defmodule Region do
  defstruct [:simbolo, :celdas, :area, :perimetro]
end

defmodule Mapa do
  # Cuadrícula %{{fila, columna} => simbolo}; las coordenadas empiezan en 0
  def construir(filas) do
    for {simbolos, f} <- Enum.with_index(filas), {s, c} <- Enum.with_index(simbolos), into: %{},
      do: {{f, c}, s}
  end

  # Recorre las casillas por filas y columnas ascendentes y arma una región
  # por cada casilla aún no visitada que no sea fondo. El orden da los IDs.
  def regiones(grid, num_filas, num_columnas) do
    casillas = for f <- 0..(num_filas - 1)//1, c <- 0..(num_columnas - 1)//1, do: {f, c}
    recorrer(casillas, grid, MapSet.new(), [])
  end

  defp recorrer([], _grid, _visitadas, regiones), do: Enum.reverse(regiones)

  defp recorrer([celda | resto], grid, visitadas, regiones) do
    simbolo = Map.fetch!(grid, celda)

    if simbolo == "." or MapSet.member?(visitadas, celda) do
      recorrer(resto, grid, visitadas, regiones)
    else
      {visitadas, celdas} = explorar(grid, simbolo, celda, visitadas, [])
      celdas = Enum.sort(celdas)

      region = %Region{
        simbolo: simbolo,
        celdas: celdas,
        area: length(celdas),
        perimetro: perimetro(grid, simbolo, celdas)
      }

      recorrer(resto, grid, visitadas, [region | regiones])
    end
  end

  # Explora recursivamente los vecinos horizontales y verticales con el mismo
  # símbolo; una casilla visitada no se vuelve a recorrer.
  defp explorar(grid, simbolo, celda, visitadas, celdas) do
    if Map.get(grid, celda) != simbolo or MapSet.member?(visitadas, celda) do
      {visitadas, celdas}
    else
      celda
      |> vecinos()
      |> Enum.reduce({MapSet.put(visitadas, celda), [celda | celdas]}, fn v, {vis, cs} ->
        explorar(grid, simbolo, v, vis, cs)
      end)
    end
  end

  defp vecinos({f, c}), do: [{f - 1, c}, {f + 1, c}, {f, c - 1}, {f, c + 1}]

  # Lados que tocan el borde (fuera del mapa) o una casilla de otro símbolo
  defp perimetro(grid, simbolo, celdas),
    do: length(for celda <- celdas, v <- vecinos(celda), Map.get(grid, v) != simbolo, do: v)

  # Caja envolvente {fila_min, columna_min} a {fila_max, columna_max}
  def caja(%Region{celdas: celdas}) do
    {filas, columnas} = Enum.unzip(celdas)
    {{Enum.min(filas), Enum.min(columnas)}, {Enum.max(filas), Enum.max(columnas)}}
  end

  # {valor máximo, IDs con ese valor} para :area o :perimetro, con empates
  def maximos([], _campo), do: {nil, []}

  def maximos(regiones, campo) do
    max = regiones |> Enum.map(&Map.get(&1, campo)) |> Enum.max()
    {max, for({r, id} <- Enum.with_index(regiones, 1), Map.get(r, campo) == max, do: id)}
  end
end
