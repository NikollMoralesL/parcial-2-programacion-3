# Problema 2 - Regiones en un mapa de colores y exportación SVG
# Uso: elixir main.exs [carpeta]   (por defecto: datos)

Code.require_file("color.exs", __DIR__)
Code.require_file("validacion.exs", __DIR__)
Code.require_file("mapa.exs", __DIR__)

defmodule Main do
  @lado 40

  def ejecutar(carpeta) do
    [mapa_txt, paleta_csv] =
      rutas = Enum.map(["mapa.txt", "paleta.csv"], &Path.join(carpeta, &1))

    case Enum.reject(rutas, &File.exists?/1) do
      [] -> procesar(carpeta, mapa_txt, paleta_csv)
      faltan -> Enum.each(faltan, &IO.puts("Error: falta el archivo requerido #{&1}"))
    end
  end

  defp procesar(carpeta, mapa_txt, paleta_csv) do
    filas = mapa_txt |> lineas() |> Stream.map(fn {n, t} -> {n, String.split(t)} end) |> Enum.to_list()
    paleta = paleta_csv |> lineas() |> Stream.map(fn {n, t} -> {n, Color.parse(t)} end) |> Enum.to_list()

    errores = Validacion.validar(filas, paleta)

    File.open!(Path.join(carpeta, "validacion_mapa.txt"), [:write, :utf8], fn f ->
      Enum.each(errores, &IO.puts(f, &1))
    end)

    if errores == [] do
      colores = for {_, {:ok, color}} <- paleta, into: %{}, do: {color.simbolo, color.hex}
      generar(carpeta, Enum.map(filas, &elem(&1, 1)), colores)
    else
      # Con errores no se calculan regiones ni SVG; se quitan los de una ejecución anterior
      Enum.each(["regiones.csv", "mapa_regiones.svg", "resumen_regiones.txt"], &File.rm(Path.join(carpeta, &1)))
      IO.puts("Validación: #{length(errores)} problemas (ver validacion_mapa.txt). No se calculan regiones.")
    end
  end

  # Líneas útiles {número_físico, texto}, sin vacías ni comentarios
  defp lineas(ruta) do
    ruta
    |> File.stream!()
    |> Stream.map(&String.trim_trailing/1)
    |> Stream.with_index(1)
    |> Stream.reject(fn {texto, _} ->
      limpio = String.trim(texto)
      limpio == "" or String.starts_with?(limpio, "#")
    end)
    |> Stream.map(fn {texto, n} -> {n, texto} end)
  end

  defp generar(carpeta, filas, colores) do
    grid = Mapa.construir(filas)
    num_filas = length(filas)
    num_columnas = length(hd(filas))
    regiones = Mapa.regiones(grid, num_filas, num_columnas)

    escribir_csv(Path.join(carpeta, "regiones.csv"), regiones)
    escribir_svg(Path.join(carpeta, "mapa_regiones.svg"), grid, regiones, colores, num_filas, num_columnas)
    escribir_resumen(Path.join(carpeta, "resumen_regiones.txt"), regiones)
  end

  defp escribir_csv(ruta, regiones) do
    File.open!(ruta, [:write, :utf8], fn csv ->
      IO.puts(csv, "id;simbolo;area;perimetro;desde;hasta")

      regiones
      |> Enum.with_index(1)
      |> Enum.each(fn {r, id} ->
        {{f1, c1}, {f2, c2}} = Mapa.caja(r)
        IO.puts(csv, "#{id};#{r.simbolo};#{r.area};#{r.perimetro};{#{f1},#{c1}};{#{f2},#{c2}}")
      end)
    end)
  end

  # El SVG se escribe por fragmentos: encabezado, rectángulos, textos y cierre
  defp escribir_svg(ruta, grid, regiones, colores, num_filas, num_columnas) do
    File.open!(ruta, [:write, :utf8], fn svg ->
      IO.puts(svg, ~s|<?xml version="1.0" encoding="UTF-8"?>|)

      IO.puts(svg, ~s|<svg xmlns="http://www.w3.org/2000/svg" width="#{@lado * num_columnas}" | <>
        ~s|height="#{@lado * num_filas}">|)

      grid
      |> Enum.sort()
      |> Enum.each(fn {{f, c}, s} ->
        IO.puts(svg, ~s|  <rect x="#{c * @lado}" y="#{f * @lado}" width="#{@lado}" height="#{@lado}" | <>
          ~s|fill="#{escapar(colores[s])}" stroke="#333333" stroke-width="1"/>|)
      end)

      # ID en la primera casilla de cada región
      regiones
      |> Enum.with_index(1)
      |> Enum.each(fn {%{celdas: [{f, c} | _]}, id} ->
        IO.puts(svg, ~s|  <text x="#{c * @lado + 20}" y="#{f * @lado + 25}" text-anchor="middle" | <>
          ~s|font-family="sans-serif" font-size="14">#{escapar(to_string(id))}</text>|)
      end)

      IO.puts(svg, "</svg>")
    end)
  end

  # Número de regiones y máximos: en pantalla y en resumen_regiones.txt
  defp escribir_resumen(ruta, regiones) do
    File.open!(ruta, [:write, :utf8], fn res ->
      [
        "Regiones: #{length(regiones)}",
        "Mayor área: #{maximo(regiones, :area)}",
        "Mayor perímetro: #{maximo(regiones, :perimetro)}"
      ]
      |> Enum.each(fn linea ->
        IO.puts(res, linea)
        IO.puts(linea)
      end)
    end)
  end

  defp maximo(regiones, campo) do
    case Mapa.maximos(regiones, campo) do
      {nil, []} -> "ninguna"
      {max, ids} -> "#{max} | regiones: #{Enum.join(ids, ", ")}"
    end
  end

  defp escapar(texto) do
    texto
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&apos;")
  end
end

Main.ejecutar(List.first(System.argv(), Path.join(__DIR__, "datos")))
