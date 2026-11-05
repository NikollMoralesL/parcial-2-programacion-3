# Color de la paleta: símbolo, nombre y color hexadecimal.
defmodule Color do
  defstruct [:simbolo, :nombre, :hex]

  # "simbolo,nombre,color_hex" -> {:ok, %Color{}} | {:error, motivo}
  def parse(texto) do
    case texto |> String.split(",") |> Enum.map(&String.trim/1) do
      [s, n, h] when s != "" and n != "" and h != "" -> {:ok, %Color{simbolo: s, nombre: n, hex: h}}
      [_, _, _] -> {:error, "hay campos vacíos"}
      campos -> {:error, "se esperaban 3 campos y hay #{length(campos)}"}
    end
  end
end
