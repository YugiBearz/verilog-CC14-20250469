# Registro de Asistencia por IA — Sistemas Digitales (ITLA)

**Estudiante:** Urik Valenzuela · Matrícula: 20250469  
**Asignatura:** Sistemas Digitales con FPGA · Reto CC14: Cola de notas de cuatro posiciones (FIFO síncrona)  

| Fecha | Herramienta | Prompt / Consulta Realizada | Resumen de Acción y Respuesta | Verificación Humana |
| :--- | :--- | :--- | :--- | :--- |
| 2026-11-01 | Antigravity AI | "Lectura y análisis de rúbrica CC14 (25 pts), arquitectura de FIFO síncrona y contrato de E/S" | Definición de interfaz top_module (K=3, cmd, data, y), reglas de reset síncrono prioritario y protocolo de pulsos push_ok/pop_ok de 1 ciclo | Revisión detallada de la rúbrica oficial y confirmación del mapeo de bits en el vector de salida y[15:0] |
| 2026-11-03 | Antigravity AI | "Decodificación segura de comandos de entrada y aislamiento de nota musical en top_module" | Extracción combinacional de push_cmd=cmd[0], pop_cmd=cmd[1] y data[3:0] ignorando data[7:4] para evitar warnings de unused bits | Comprobación con linter de que los bits cmd[7:2] y data[7:4] no introducen fallos de rango |
| 2026-11-03 | Antigravity AI | "Estructura de reset síncrono prioritario y generación de pulsos monopulso según rúbrica" | Implementación de reset con prioridad absoluta sobre en y comandos; forzado de push_ok y pop_ok a 0 en cada flanco positivo de clk aun con en=0 | Verificación estricta de que los pulsos duran exactamente 1 ciclo de reloj y no quedan enclavados |
