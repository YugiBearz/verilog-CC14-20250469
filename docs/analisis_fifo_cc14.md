# Análisis Teórico de Arquitectura — Reto CC14 (FIFO Síncrona)
**Estudiante:** Urik Camilo Valenzuela Flynn · Matrícula: 20250469  
**Asignatura:** Sistemas Digitales con FPGA · ITLA (Prof. Wilkins Cedano)

---

## 1. Modelo de Punteros Circulares y Ocupación
La cola de 4 posiciones implementa dos punteros de 2 bits:
* Puntero de escritura: `wr_ptr` $\in \{0, 1, 2, 3\}$.
* Puntero de lectura: `rd_ptr` $\in \{0, 1, 2, 3\}$.

La ocupación se cuantifica mediante un registro independiente de 3 bits:
$$\text{count} \in \{0, 1, 2, 3, 4\}$$
Esto desacopla la ambigüedad tradicional de punteros iguales (`wr_ptr == rd_ptr`) entre cola vacía y cola llena.

## 2. Matriz de Decisiones y Transferencias Simultáneas
| `count` previo | `push` | `pop` | Acción PUSH | Acción POP | `count` resultante | `push_ok` | `pop_ok` |
| :---: | :---: | :---: | :--- | :--- | :---: | :---: | :---: |
| $0$ | 1 | 1 | Aceptado en `mem[wr_ptr]` | **Rechazado (No bypass)** | 1 | 1 | 0 |
| $1..3$ | 1 | 1 | Aceptado en `mem[wr_ptr]` | Aceptado de `mem[rd_ptr]` | Constante | 1 | 1 |
| $4$ | 1 | 1 | Aceptado (Reemplazo circular) | Aceptado (Nota más antigua) | 4 | 1 | 1 |

## 3. Protocolo de Monopulsos de Aceptación
`push_ok` y `pop_ok` operan como pulsos activos de 1 ciclo:
$$\forall \text{ flanco posedge } clk: \quad push\_ok \leftarrow 0, \quad pop\_ok \leftarrow 0$$
Incluso cuando $en = 0$, garantizando que una pausa del sistema nunca congele las banderas en alto.

## 4. Verificación Estroboscópica
Para evitar condiciones de carrera asociadas a la simulación por eventos discretos de Verilog, el banco de pruebas muestrea las salidas 1 ns después de cada flanco positivo:
$$t_{\text{sample}} = t_{\text{posedge}} + 1\text{ ns}$$
Esto asegura que las señales combinacionales y los registros del DUT se hayan estabilizado antes de la comparación.
