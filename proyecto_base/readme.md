<!-- markdownlint-disable-file MD013 -->
# Proyecto de ejemplo VHDL

Electrónica II para Ingeniería Electrónica (E23) 2025

## Descripción

El objeto de este proyecto es brindar un punto de partida para que los alumnos de Electrónica II creen sus propios proyectos de descripción de hardware en VHDL, síntesis y configuración de FPGA iCE40Hx4k

## Contenido

- **makefile** : Guión de make para automatizar la compilación, simulación, síntesis lógica y programación.
  - Para mayor información sobre el uso de make en este proyecto ejecutar el comando `make help`
- **src/** : Directorio de código fuente, donde se ubicarán los archivos de descripción de hardware (usando extensión .vhd) y de restricciones para el sintetizador (.pcf, usados para especificar los pines a los que se conectarán las entradas y salidas de la entidad sintetizada)
- **out/** : Directorio creado por *make* donde se guardan las formas de onda de simulación (archivos .ghw) y los bitstream de configuración para la FPGA (archivos .bin)
- **.gitignore** : Archivo que indica al sistema de control de versiones git que archivos debe monitorear y cuales no (no se deben preservar los archivos generados, solo las fuentes)
- **build/** : Directorio de trabajo, creado por *make*, donde se generan los archivos intermedios de compilación y síntesis lógica.

## Ejemplo

El proyecto incluye un ejemplo, la descripción de hardware de una compuerta AND de dos entradas, conectadas a los pulsadores S1 y S2, con su salida conectada al led D3 de la placa de desarrollo EDU-CIAA-FPGA basada en la FPGA iCE40Hx4k.

- **src/ejemplo.vhd** : Definición de la entidad *ejemplo* y su arquitectura. Descripción de una compuerta AND.
  - Para sintetizar la entidad utilizar el comando `make out/ejemplo.bin`
  - Para cargar la entidad en la FPGA utilizar el comando `make out/ejemplo.load`
- **src/ejemplo.pcf** : Especificación de conexión de la entidad *ejemplo* a los pines de la FPGA, incluye comentarios útiles para escribir otras especificaciones para la misma placa.
- **src/ejemplo_tb.vhd** : Simulación de la entidad *ejemplo* siendo estimulada con la secuencia 00 01 11 10 en sus entradas.
  - Para correr la simulación usar el comando `make out/ejemplo_tb.ghw`
  - Para ver los resultados (una vez ejecutada la simulación) usar el comando `gtkwave out/ejemplo_tb.ghw`
