# Tramo dirigido. linea y texto guardan la línea física original del archivo.
defmodule Tramo do
  defstruct [:origen, :destino, :minutos, :costo, :linea, :texto]

  # "origen,destino,minutos,costo" -> {:ok, %Tramo{}} | {:error, motivo}
  def parse(texto) do
    case texto |> String.split(",") |> Enum.map(&String.trim/1) do
      [o, d, m, c] ->
        with :ok <- no_vacio(o, "origen"),
             :ok <- no_vacio(d, "destino"),
             {:ok, m} <- entero_positivo(m, "minutos"),
             {:ok, c} <- entero_positivo(c, "costo") do
          {:ok, %Tramo{origen: o, destino: d, minutos: m, costo: c, texto: texto}}
        end

      campos ->
        {:error, "se esperaban 4 campos y hay #{length(campos)}"}
    end
  end

  defp no_vacio("", campo), do: {:error, "#{campo} vacío"}
  defp no_vacio(_, _), do: :ok

  defp entero_positivo(texto, campo) do
    case Integer.parse(texto) do
      {n, ""} when n > 0 -> {:ok, n}
      {_, ""} -> {:error, "#{campo} debe ser positivo"}
      _ -> {:error, "#{campo} no es un entero"}
    end
  end
end
