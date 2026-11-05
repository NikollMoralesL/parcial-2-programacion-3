defmodule Itinerario do
  defstruct centros: [], tramos: [], minutos: 0, costo: 0
end

defmodule Red do
  # %{origen => [tramos que salen]}, en el orden del archivo
  def construir(tramos) do
    tramos
    |> Enum.reverse()
    |> Enum.reduce(%{}, fn t, g -> Map.update(g, t.origen, [t], &[t | &1]) end)
  end

  def centros(tramos), do: tramos |> Enum.flat_map(&[&1.origen, &1.destino]) |> MapSet.new()

  # Búsqueda recursiva de todos los itinerarios simples
  def buscar(grafo, origen, destino),
    do: explorar(grafo, origen, destino, MapSet.new([origen]), %Itinerario{centros: [origen]})

  defp explorar(_grafo, destino, destino, _visitados, %Itinerario{} = it),
    do: [%Itinerario{it | centros: Enum.reverse(it.centros), tramos: Enum.reverse(it.tramos)}]

  defp explorar(grafo, actual, destino, visitados, it) do
    grafo
    |> Map.get(actual, [])
    |> Enum.reject(&MapSet.member?(visitados, &1.destino))
    |> Enum.flat_map(fn t ->
      siguiente = %Itinerario{
        centros: [t.destino | it.centros],
        tramos: [t | it.tramos],
        minutos: it.minutos + t.minutos,
        costo: it.costo + t.costo
      }

      explorar(grafo, t.destino, destino, MapSet.put(visitados, t.destino), siguiente)
    end)
  end

  # Números de los itinerarios óptimos por criterio, con empates
  def optimos(itinerarios) do
    numerados = Enum.with_index(itinerarios, 1)

    for {nombre, criterio} <- [tramos: &length(&1.tramos), tiempo: & &1.minutos, costo: & &1.costo],
        into: %{} do
      minimo = numerados |> Enum.map(fn {it, _} -> criterio.(it) end) |> Enum.min()
      {nombre, for({it, n} <- numerados, criterio.(it) == minimo, do: n)}
    end
  end

  # Stream infinito de conjuntos alcanzables; se corta en el primer estado
  # repetido consecutivo. Emite {paso, conjunto}.
  def alcance(grafo, origen) do
    MapSet.new([origen])
    |> Stream.iterate(fn s ->
      Enum.reduce(s, s, fn c, acc ->
        grafo |> Map.get(c, []) |> Enum.reduce(acc, &MapSet.put(&2, &1.destino))
      end)
    end)
    |> Stream.with_index()
    |> Stream.transform(nil, fn {estado, paso}, anterior ->
      if estado == anterior, do: {:halt, anterior}, else: {[{paso, estado}], estado}
    end)
  end
end
