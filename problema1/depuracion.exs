# Validación previa recursiva (sin Enum ni Stream).
# Descarta bucles y parejas origen->destino repetidas (se conserva la primera).
# Devuelve {conservados, [{tramo, motivo}]}.
defmodule Depuracion do
  def depurar(tramos), do: depurar(tramos, %{}, [], [])

  defp depurar([], _vistos, ok, desc), do: {invertir(ok, []), invertir(desc, [])}

  defp depurar([%{origen: c, destino: c} = t | resto], vistos, ok, desc),
    do: depurar(resto, vistos, ok, [{t, "bucle en el centro #{c}"} | desc])

  defp depurar([t | resto], vistos, ok, desc) do
    case Map.fetch(vistos, {t.origen, t.destino}) do
      {:ok, primera} ->
        depurar(resto, vistos, ok, [{t, "repetido, primera aparición en la línea #{primera}"} | desc])

      :error ->
        depurar(resto, Map.put(vistos, {t.origen, t.destino}, t.linea), [t | ok], desc)
    end
  end

  defp invertir([], acc), do: acc
  defp invertir([h | t], acc), do: invertir(t, [h | acc])
end
