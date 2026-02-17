<FullCalendar
  plugins={[dayGridPlugin, timeGridPlugin, interactionPlugin]}
  initialView="dayGridMonth"
  headerToolbar={{
    left: "prev,next today",
    center: "title",
    right: "dayGridMonth,timeGridWeek,timeGridDay"
  }}
  slotMinTime="06:00:00"
  slotMaxTime="22:00:00"
  nowIndicator={true}
  selectable={true}
  editable={true}
  height="auto"
  events={events.map(e => ({
    id: e.id,
    title: e.title,
    start: e.startAt,
    end: e.endAt,
    backgroundColor: e.type.colorHex,
    borderColor: e.type.colorHex
  }))}
  dateClick={(info) => openCreateModal(info.date)}
  eventClick={(info) => openEditModal(info.event.id)}
  eventDrop={(info) => updateEventFromCalendar(info.event)}
  eventResize={(info) => updateEventFromCalendar(info.event)}
/>
