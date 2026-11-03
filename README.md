# Segundo Parcial — Sistemas Digitales con FPGA (ITLA)
## Reto CC14 (25 puntos): Cola de Notas de Cuatro Posiciones (FIFO Síncrona)

- **Estudiante:** Urik Camilo Valenzuela Flynn
- **Matrícula:** 20250469
- **Correo Institucional:** 20250469@itla.edu.do
- **Asignatura:** Sistemas Digitales con FPGA · ITLA (Prof. Wilkins Cedano)
- **Repositorio Oficial:** [GitHub - YugiBearz/verilog-CC14-20250469](https://github.com/YugiBearz/verilog-CC14-20250469)

---

### Descripción del Reto CC14
Diseño, implementación y verificación en Verilog 2001 de una cola síncrona FIFO (First-In, First-Out) de 4 posiciones para almacenar notas musicales de 4 bits (0 a 15), gobernada por un reloj de sistema `clk` y parametrizable con factor $K$. El diseño incorpora reset síncrono prioritario, habilitador de operación `en`, decodificación de comandos de inserción (`push`) y extracción (`pop`), y generación de pulsos de aceptación de 1 ciclo (`push_ok` y `pop_ok`).

### Especificaciones de Interfaz
- **Entradas:** `clk`, `rst` (síncrono prioritario), `en`, `cmd[7:0]` (`cmd[0]=push`, `cmd[1]=pop`), `data[7:0]` (`data[3:0]=in_note`).
- **Salida:** `y[15:0]`
  - `y[3:0]`: Última nota extraída (`last_note`).
  - `y[6:4]`: Ocupación actual de la cola (rango 0 a 4).
  - `y[7]`: Flag de aceptación `push_ok` (pulso de 1 ciclo).
  - `y[8]`: Flag de aceptación `pop_ok` (pulso de 1 ciclo).
  - `y[15:9]`: Bits reservados fijados en 0.

---

### Estado del Desarrollo
- [x] **Fase 0: Configuración Inicial** — Estructura del repositorio, exclusiones en `.gitignore` y entorno en `.vscode`.
- [x] **Fase 1: Bitácora y Arquitectura Base** — Registro obligatorio en `AI_LOG.md` y definición de interfaz parametrizada en `top_module.v`.
- [x] **Fase 2: Implementación RTL (FIFO)** — Memoria interna de 4 notas, punteros circulares, reset prioritario, PUSH, POP y transferencias simultáneas.
- [x] **Fase 3: Herramientas y Automatización** — Reglas de `Makefile` (`check`, `check-k5`, `lint`, `clean`) y tareas de VS Code.
- [x] **Fase 4: Verificación Exhaustiva (G1 a G6)** — Banco `tb_student.v`, casos límite, colisiones y 900 ciclos aleatorios con modelo de oro.
- [ ] **Fase 5: Parametricidad K=5 y Documentación** — Validación de portabilidad con K=5, análisis en `docs/` y archivo de entregables final.
