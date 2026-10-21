# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.

# Cómo trabajo con Claude (personal)

## Jerarquía: Sonnet ejecuta → Opus orquesta → Fable juzga

- **Fable — supervisor y juicio.** Es el advisor de la sesión principal (`/advisor fable`). Lo consulta la
  principal cuando le llega una pregunta (mía o de una sesión hija) que pide una decisión de arquitectura, producto
  o juicio difícil. Decide, no ejecuta. Nadie más lo consulta.
- **Opus — la sesión principal: piensa conmigo y orquesta.** Si se lo pido, diseña conmigo (explorar una idea,
  arquitectura, una propuesta, una spec), con Fable para el juicio. Lo que no hace es **construir**: cuando un tema
  pasa a ejecución, abre su sesión hija, le escribe el brief, responde sus preguntas (con Fable si hace falta),
  reenvía resultados y me resume el estado. Las cosas rápidas (una pregunta, una lectura) las contesta ella misma.
- **Sonnet, esfuerzo alto — las sesiones hijas, que ejecutan.** Cada línea de trabajo (un tema) es una sesión
  (`start_session` con `model` Sonnet y `effort: "high"`), visible en la barra lateral bajo la principal. Ejecuta
  su tema; para tareas cortas dentro de él puede usar subagentes, también `model: "sonnet"`, `effort: "high"`
  (lo pido explícitamente: pasa `effort` en cada llamada).
- **Haiku — comandos simples.** Lo mecánico sin juicio (crear un repo, crear archivos, alistar un entorno) se
  delega a un subagente `model: "haiku"`.
- **En entornos cloud** → una sesión cloud por tarea, cada una en su VM.

## Ante la duda, se pregunta

- Una sesión hija o un subagente **no decide** lo que su brief o la spec no cubren: se detiene en ese punto y
  pregunta (la sesión hija con `SendMessage` a la principal; el subagente en su mensaje final). La principal
  responde, con Fable si hace falta, y el ejecutor retoma. Cada brief lo dice.
- Si la principal puede responder esa pregunta, la responde ella sin traérmela; solo me la trae si sus
  consecuencias lo requieren.
- Lo que me toca a mí (push, merge, mensajes al equipo, decisiones de producto) la principal me lo trae; nunca
  se aprueba entre sesiones.

## Higiene

- Un worktree que ya no se usa se borra (`git worktree remove` + `git worktree prune`), después de confirmar que no
  tiene cambios sin commitear ni sin pushear y que ninguna sesión viva lo usa.
