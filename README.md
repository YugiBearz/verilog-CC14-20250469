# Segundo Parcial — Sistemas Digitales con FPGA (ITLA)
## Reto CC14 (25 puntos): Cola de Notas de Cuatro Posiciones (FIFO Síncrona)

- **Estudiante:** Urik Camilo Valenzuela Flynn
- **Matrícula:** 20250469
- **Correo Institucional:** 20250469@itla.edu.do
- **Docente:** Prof. Wilkins Gabriel Cedano Del Rosario
- **Asignatura:** Sistemas Digitales con FPGA · ITLA
- **Repositorio Oficial:** [GitHub - YugiBearz/verilog-CC14-20250469](https://github.com/YugiBearz/verilog-CC14-20250469)

---

### Descripción del Reto CC14
Diseño, implementación y verificación en Verilog 2001 de una cola síncrona FIFO (*First-In, First-Out*) de 4 posiciones para almacenar notas musicales de 4 bits (0 a 15), gobernada por un reloj de sistema `clk` y parametrizable con factor $K$. El diseño incorpora reset síncrono prioritario, habilitador de operación `en`, decodificación de comandos de inserción (`push`) y extracción (`pop`), y generación de pulsos de aceptación de 1 ciclo (`push_ok` y `pop_ok`).

### Especificaciones de Interfaz
- **Entradas:** `clk`, `rst` (síncrono prioritario), `en`, `cmd[7:0]` (`cmd[0]=push`, `cmd[1]=pop`), `data[7:0]` (`data[3:0]=in_note`).
- **Salida:** `y[15:0]`
  - `y[3:0]`: Última nota extraída (`last_note`).
  - `y[6:4]`: Ocupación actual de la cola (rango 0 a 4).
  - `y[7]`: Flag de aceptación `push_ok` (pulso de 1 ciclo).
  - `y[8]`: Flag de aceptación `pop_ok` (pulso de 1 ciclo).
  - `y[15:9]`: Bits reservados fijados estrictamente en 0.

---

### Arquitectura y Prioridades de Control

El diseño se estructura bajo un control jerárquico estricto en cada flanco positivo de `clk`:

1. **Prioridad 1 — Reset Síncrono (`rst = 1`):**
   - Máxima prioridad del sistema: anula cualquier habilitación `en` y cualquier comando entrante en `cmd`.
   - Limpia la memoria interna a cero, reinicia los punteros circulares `wr_ptr <= 0`, `rd_ptr <= 0`, fija la ocupación `count <= 0`, resetea `last_note <= 0` y apaga los pulsos `push_ok <= 0`, `pop_ok <= 0`.
2. **Prioridad 2 — Supresión de Aceptaciones en Inhabilitación (`en = 0`):**
   - Según el contrato funcional, las señales de aceptación `push_ok` y `pop_ok` son estrictamente monopulso (1 ciclo de reloj) y se borran a 0 en cada flanco positivo de `clk`, **incluso cuando `en = 0`**.
   - Con `en = 0`, el estado de la memoria, punteros, contador de ocupación y última nota extraída permanecen congelados.
3. **Prioridad 3 — Operación Habilitada (`en = 1`):**
   - Las decisiones se toman usando la **ocupación previa** al flanco actual:
     - **POP:** Se acepta si `cmd[1] = 1` y la cola no estaba vacía (`count > 0`).
     - **PUSH:** Se acepta si `cmd[0] = 1` y había espacio (`count < 4`) o si en el mismo ciclo se acepta un POP.
     - **Transferencia Simultánea en Vacío (`count == 0` con PUSH y POP):** Solo se acepta PUSH; no hay bypass (la nota entrante no puede salir en el mismo ciclo).
     - **Transferencia Simultánea en Lleno (`count == 4` con PUSH y POP):** Se aceptan ambos; se extrae la nota más antigua y se inserta la nueva nota en el espacio liberado, manteniendo `count = 4`.

---

### Instrucciones de Reproducción y Verificación

#### Opción A: Desde la Terminal (Makefile)
```bash
make check      # Simulación con K=3 (945 pruebas ciclo a ciclo, 100% PASS)
make check-k5   # Simulación con K=5 (945 pruebas ciclo a ciclo, 100% PASS)
make lint       # Verificación estática con Verilator (-Wall)
make clean      # Limpieza de ejecutables temporales
```

#### Opción B: Comando Oficial del Mandato
```bash
iverilog -g2012 -s tb_student -o sim top_module.v tb_student.v
vvp sim
```

---

### Matriz de Verificación (100% PASS — 945 Comprobaciones)
| Grupo | Caso de Prueba | Aserciones | Estado |
| :--- | :--- | :---: | :---: |
| G0 | Reset Inicial y Ejemplo Oficial | 6 | PASS |
| G1 | Reset con FIFO Llena | 5 | PASS |
| G2 | Orden FIFO y Envoltura Circular | 11 | PASS |
| G3 | Rechazos en Frontera (Vacío / Lleno) | 10 | PASS |
| G4 | Transferencias Simultáneas (Push+Pop) | 6 | PASS |
| G5 | Pausa con `en=0` y Supresión de Pulsos | 6 | PASS |
| G6 | 900 Ciclos Aleatorios con Modelo de Oro | 901 | PASS |
| **Total** | **Verificación Completa (K=3 y K=5)** | **945** | **100% PASS** |

---

### Historial de Avance Progresivo (Tabla de Commits con Hash)

| Hash | Fecha | Mensaje / Etapa | Descripción del Avance Logrado |
| :---: | :---: | :--- | :--- |
| `41b8e8d` | 2026-11-01 | `chore: inicializar estructura de repositorio y configuracion de entorno` | Creación de estructura inicial, `.gitignore` y configuración base. |
| `84268b6` | 2026-11-01 | `docs: inicializar README con especificacion de reto CC14 y fases de avance` | Documentación inicial del reto CC14 y planificación de fases. |
| `74195ea` | 2026-11-01 | `docs: inicializar bitacora obligatoria de asistencia de IA (AI_LOG.md)` | Creación de la bitácora obligatoria con registro de prompts y auditoría. |
| `28f96fb` | 2026-11-03 | `feat: definir cabecera parametrizada e interfaz de puertos de top_module` | Declaración de puertos síncronos y parámetro `K=3` en `top_module.v`. |
| `fe00070` | 2026-11-03 | `feat: implementar decodificacion de comandos y extraccion de nota musical` | Extracción de `push_cmd`, `pop_cmd` y `data[3:0]` ignorando bits altos. |
| `86d2118` | 2026-11-03 | `feat: declarar banco de memoria de 4 posiciones y registros de estado interno` | Declaración de memoria `mem[0:3]`, punteros circulares y contador `count`. |
| `8b7d397` | 2026-11-03 | `feat: implementar bloque secuencial con reset sincrono prioritario y borrado de pulsos` | Lógica síncrona con prioridad de reset y forzado a 0 de pulsos `ok`. |
| `3aaf125` | 2026-11-03 | `feat: implementar logica de operacion POP con captura de nota y avance circular` | Lógica de extracción de nota más antigua, avance de `rd_ptr` y flag `pop_ok`. |
| `67e1092` | 2026-11-03 | `feat: implementar logica de operacion PUSH con almacenamiento y avance de puntero` | Inserción de nota, avance de `wr_ptr` y generación de flag `push_ok`. |
| `2f7abcf` | 2026-11-03 | `feat: implementar transferencias simultaneas y empaquetado de bus de salida y` | Manejo de push+pop concurrentes sin bypass y empaquetado de `y[15:0]`. |
| `41760b9` | 2026-11-03 | `build: integrar automatizacion con Makefile y tareas para VS Code` | Automatización de compilación con Icarus Verilog y tareas en `.vscode`. |
| `7fdaae2` | 2026-11-03 | `test: construir andamiaje base del banco de pruebas tb_student` | Creación del banco de pruebas base con reloj y generador de estímulos. |
| `c975220` | 2026-11-03 | `test: implementar tareas de muestreo sincrono check_outputs y step_cycle` | Tareas de verificación estroboscópica evaluadas a 1 ns post-flanco. |
| `6f1be3c` | 2026-11-03 | `test: verificar secuencia del ejemplo oficial y grupo G1 (reset sincrono)` | Validación del ejemplo del mandato (Push 5, Push 9, Pop, Pop) y G1. |
| `000d332` | 2026-11-03 | `test: agregar grupo G2 (orden FIFO estricto y envoltura completa de punteros)` | Comprobación de wrap-around circular de punteros `wr_ptr` y `rd_ptr`. |
| `77759d2` | 2026-11-03 | `test: agregar grupo G3 (rechazos en frontera) y grupo G4 (transferencias concurrentes)` | Pruebas de rechazo en vacío/lleno y push+pop simultáneos en los 3 estados. |
| `b5239fc` | 2026-11-03 | `test: agregar grupo G5 (pausa con en=0 y verificacion de bits y[15:9] en cero)` | Validación de supresión de aceptaciones durante pausa y ceros en `y[15:9]`. |
| `1213b90` | 2026-11-03 | `test: incorporar estructura de modelo de oro y generador pseudoaleatorio en tb_student` | Andamiaje para verificación masiva automatizada con modelo de referencia. |
| `060f368` | 2026-11-03 | `test: completar logica de modelo de oro con 900 ciclos aleatorios y reporte final` | Ejecución de 900 ciclos aleatorios (G6) totalizando 945 aserciones correctas. |
| `2e0e89a` | 2026-11-03 | `test: validar parametricidad de diseno con factor K=5 (945 pruebas superadas)` | Verificación de portabilidad compilando con `K=5` sin alteración funcional. |
| `749b94a` | 2026-11-03 | `docs: documentar analisis teorico de arquitectura y casos limite en docs/analisis_fifo_cc14.md` | Documento de análisis formal con diagramas y casos límite para defensa. |
| `3b79aa0` | 2026-11-03 | `docs: actualizar README con instrucciones de ejecucion, matriz 100% PASS y cierre de bitacora` | Consolidación de instrucciones y matriz de pruebas superadas al 100%. |
| `cc3fae8` | 2026-11-03 | `docs: generar archivo oficial de entregables ENTREGABLES_CC14_20250469.txt` | Resumen oficial con hashes y datos institucionales de entrega. |
| `2bf6925` | 2026-11-07 | `feat(fpga): implementar sincronizador 2ff parametrizable contra metaestabilidad` | Creación de `sync2ff.v` para acondicionamiento de entradas mecánicas. |
