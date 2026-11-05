# Problema 1 - Rutas de entrega en una red dirigida
# Uso: elixir main.exs [carpeta]   (por defecto: datos)

Code.require_file("tramo.exs", __DIR__)
Code.require_file("depuracion.exs", __DIR__)
Code.require_file("red.exs", __DIR__)

defmodule Main do
  def ejecutar(carpeta) do
    [tramos_csv, consultas_txt] =
      rutas = Enum.map(["tramos.csv", "consultas.txt"], &Path.join(carpeta, &1))

    case Enum.reject(rutas, &File.exists?/1) do
      [] -> procesar(carpeta, tramos_csv, consultas_txt)
      faltan -> Enum.each(faltan, &IO.puts("Error: falta el archivo requerido #{&1}"))
    end
  end

  defp procesar(carpeta, tramos_csv, consultas_txt) do
    {validos, errores} =
      tramos_csv
      |> lineas()
      |> Stream.map(fn {n, texto} -> {n, texto, Tramo.parse(texto)} end)
      |> Enum.reduce({[], []}, fn
{n, _, {:ok, t}}, {ok, err} -> {[%{t | linea: n} | ok], err}
        {n, texto, {:error, motivo}}, {ok, err} -> {ok, [{n, texto, motivo} | err]}
      end)
      |> then(fn {ok, err} -> {Enum.reverse(ok), Enum.reverse(err)} end)

    escribir(Path.join(carpeta, "errores_tramos.txt"), errores, fn {n, texto, motivo} ->
      "Línea #{n}: #{texto} | #{motivo}"
    end)

    {conservados, descartes} = Depuracion.depurar(validos)

    escribir(Path.join(carpeta, "depuracion_tramos.txt"), descartes, fn {t, motivo} ->
      "Línea #{t.linea}: #{t.texto} | #{motivo}"
    end)

    grafo = Red.construir(conservados)
    centros = Red.centros(conservados)

    File.open!(Path.join(carpeta, "itinerarios.txt"), [:write, :utf8], fn itin ->
      File.open!(Path.join(carpeta, "alcance_centros.txt"), [:write, :utf8], fn alc ->
        consultas_txt
        |> lineas()
        |> Enum.each(&atender(&1, grafo, centros, itin, alc))
      end)
    end)
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

  defp escribir(ruta, registros, formato) do
    File.open!(ruta, [:write, :utf8], fn f -> Enum.each(registros, &IO.puts(f, formato.(&1))) end)
  end

  defp atender({n, texto}, grafo, centros, itin, alc) do
    case texto |> String.split(",") |> Enum.map(&String.trim/1) do
      [o, d] when o != "" and d != "" ->
        IO.puts(itin, "=== #{o} → #{d} ===")
        buscar(o, d, grafo, centros, itin, alc)
        IO.puts(itin, "")

      _ ->
        IO.puts(itin, "Línea #{n}: #{texto} | consulta inválida\n")
        IO.puts("Línea #{n}: consulta inválida")
    end
  end

  defp buscar(o, d, grafo, centros, itin, alc) do
    case Enum.reject(Enum.uniq([o, d]), &MapSet.member?(centros, &1)) do
      [] ->
        if MapSet.member?(alcance(o, d, grafo, alc), d) do
          its = Red.buscar(grafo, o, d)
          escribir_itinerarios(itin, its)
          IO.puts("#{o} → #{d}: #{length(its)} itinerarios")
        else
          IO.puts(itin, "Sin itinerarios\nTotal: 0 itinerarios")
          IO.puts("#{o} → #{d}: 0 itinerarios (sin itinerarios)")
        end

      faltan ->
        mensaje = "centro inexistente: #{Enum.join(faltan, ", ")}"
        IO.puts(itin, "Sin itinerarios, #{mensaje}\nTotal: 0 itinerarios")
        IO.puts("#{o} → #{d}: 0 itinerarios (#{mensaje})")
    end
  end

  # Consume el Stream de alcance escribiendo cada estado; devuelve el último
  defp alcance(o, d, grafo, alc) do
    IO.puts(alc, "=== #{o} → #{d} ===")

    {paso, estado} =
      grafo
      |> Red.alcance(o)
      |> Stream.each(fn {p, e} -> IO.puts(alc, "Paso #{p}: {#{e |> Enum.sort() |> Enum.join(", ")}}") end)
      |> Enum.reduce(nil, fn x, _ -> x end)

    IO.puts(alc, "Se estabiliza en el paso #{paso}\n")
    estado
  end

  defp escribir_itinerarios(itin, its) do
    its
    |> Enum.with_index(1)
    |> Enum.each(fn {it, i} ->
      IO.puts(itin, "Itinerario #{i}: #{Enum.join(it.centros, " → ")} | tramos: #{length(it.tramos)} | " <>
        "#{it.minutos} min | costo: #{it.costo}")
    end)

    opt = Red.optimos(its)
    IO.puts(itin, "Total: #{length(its)} itinerarios")
    IO.puts(itin, "Menos tramos: #{Enum.join(opt.tramos, ", ")}")
    IO.puts(itin, "Menor tiempo: #{Enum.join(opt.tiempo, ", ")}")
    IO.puts(itin, "Menor costo: #{Enum.join(opt.costo, ", ")}")
  end
end

Main.ejecutar(List.first(System.argv(), Path.join(__DIR__, "datos")))
