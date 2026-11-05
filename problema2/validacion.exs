# Validación previa recursiva del mapa y la paleta (sin Enum ni Stream).
# filas:  [{linea, [simbolos]}]
# paleta: [{linea, {:ok, color} | {:error, motivo}}]
# Devuelve todos los problemas encontrados, en orden (vacía si no hay).
defmodule Validacion do
  def validar(filas, paleta) do
    {definidos, errores} = revisar_paleta(paleta, %{}, [])

    errores =
      if Map.has_key?(definidos, "."),
        do: errores,
        else: ["Paleta: falta el símbolo . (fondo)" | errores]

    invertir(revisar_mapa(filas, definidos, errores), [])
  end

  # definidos: %{simbolo => línea donde se declaró por primera vez}
  defp revisar_paleta([], definidos, errores), do: {definidos, errores}

  defp revisar_paleta([{n, {:error, motivo}} | resto], definidos, errores),
    do: revisar_paleta(resto, definidos, ["Paleta, línea #{n}: #{motivo}" | errores])

  defp revisar_paleta([{n, {:ok, %{simbolo: s, hex: hex}}} | resto], definidos, errores) do
    errores =
      if Regex.match?(~r/^#[0-9A-Fa-f]{6}$/, hex),
        do: errores,
        else: ["Paleta, línea #{n}: el color '#{hex}' no tiene la forma #RRGGBB" | errores]

    case Map.fetch(definidos, s) do
      {:ok, primera} ->
        error = "Paleta, línea #{n}: símbolo '#{s}' repetido (ya definido en la línea #{primera})"
        revisar_paleta(resto, definidos, [error | errores])

      :error ->
        revisar_paleta(resto, Map.put(definidos, s, n), errores)
    end
  end

  defp revisar_mapa([], _definidos, errores), do: ["Mapa: no tiene filas" | errores]

  defp revisar_mapa([{_, primera} | _] = filas, definidos, errores),
    do: revisar_filas(filas, 0, length(primera), definidos, errores)

  defp revisar_filas([], _f, _ancho, _definidos, errores), do: errores

  defp revisar_filas([{n, simbolos} | resto], f, ancho, definidos, errores) do
    errores =
      if length(simbolos) == ancho,
        do: errores,
        else: ["Mapa, línea #{n}, fila #{f}: tiene #{length(simbolos)} símbolos y se esperaban #{ancho}" | errores]

    errores = revisar_simbolos(simbolos, n, f, 0, definidos, errores)
    revisar_filas(resto, f + 1, ancho, definidos, errores)
  end

  defp revisar_simbolos([], _n, _f, _c, _definidos, errores), do: errores

  defp revisar_simbolos([s | resto], n, f, c, definidos, errores) do
    errores =
      if Map.has_key?(definidos, s),
        do: errores,
        else: ["Mapa, línea #{n}, fila #{f}, columna #{c}: símbolo '#{s}' no está en la paleta" | errores]

    revisar_simbolos(resto, n, f, c + 1, definidos, errores)
  end

  defp invertir([], acc), do: acc
  defp invertir([h | t], acc), do: invertir(t, [h | acc])
end
