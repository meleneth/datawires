import { Controller } from "@hotwired/stimulus"
import * as d3 from "d3"

export default class extends Controller {
  static targets = ["chart"]
  static values = {
    events: Array,
    timeLabel: String,
  }

  connect() {
    this.resizeObserver = new ResizeObserver(() => this.render())
    this.resizeObserver.observe(this.chartTarget)
    this.render()
  }

  disconnect() {
    if (this.resizeObserver) this.resizeObserver.disconnect()
  }

  render() {
    const events = this.eventsValue || []
    const width = Math.max(this.chartTarget.clientWidth, 320)
    const height = Math.max(260, events.length * 54 + 96)
    const margin = { top: 28, right: 32, bottom: 48, left: 56 }

    this.chartTarget.replaceChildren()

    const svg = d3
      .select(this.chartTarget)
      .append("svg")
      .attr("viewBox", `0 0 ${width} ${height}`)
      .attr("role", "img")
      .attr("aria-label", "Timeline")
      .attr("class", "h-full min-h-96 w-full")

    if (events.length === 0) {
      svg
        .append("text")
        .attr("x", width / 2)
        .attr("y", height / 2)
        .attr("text-anchor", "middle")
        .attr("class", "fill-muted-foreground text-sm")
        .text("No timeline events")
      return
    }

    const times = events.map((event) => event.relative_time)
    const extent = d3.extent(times)
    const domain = extent[0] === extent[1] ? [extent[0] - 1, extent[1] + 1] : extent
    const x = d3.scaleLinear().domain(domain).range([margin.left, width - margin.right]).nice()
    const y = d3
      .scalePoint()
      .domain(events.map((event) => event.document_id))
      .range([margin.top + 24, height - margin.bottom - 10])
      .padding(0.5)

    const axis = d3.axisBottom(x).ticks(Math.min(8, Math.max(2, events.length))).tickSizeOuter(0)

    svg
      .append("line")
      .attr("x1", margin.left)
      .attr("x2", width - margin.right)
      .attr("y1", margin.top)
      .attr("y2", margin.top)
      .attr("class", "stroke-black")
      .attr("stroke-width", 2)

    svg
      .append("g")
      .attr("transform", `translate(0, ${height - margin.bottom})`)
      .call(axis)
      .call((group) => group.select(".domain").attr("stroke-width", 2).attr("class", "stroke-black"))
      .call((group) => group.selectAll("line").attr("class", "stroke-black"))
      .call((group) => group.selectAll("text").attr("class", "fill-foreground text-xs"))

    svg
      .append("text")
      .attr("x", width / 2)
      .attr("y", height - 8)
      .attr("text-anchor", "middle")
      .attr("class", "fill-muted-foreground text-xs")
      .text(this.timeLabelValue || "Relative time")

    const eventGroups = svg
      .append("g")
      .selectAll("g")
      .data(events)
      .join("g")
      .attr("transform", (event) => `translate(${x(event.relative_time)}, ${y(event.document_id)})`)

    eventGroups
      .append("line")
      .attr("y1", () => margin.top - y(events[0].document_id))
      .attr("y2", 0)
      .attr("class", "stroke-black")
      .attr("stroke-dasharray", "3 4")

    eventGroups
      .append("circle")
      .attr("r", 8)
      .attr("class", "fill-primary stroke-black")
      .attr("stroke-width", 2)

    eventGroups
      .append("text")
      .attr("x", 14)
      .attr("y", -6)
      .attr("class", "fill-foreground font-head text-sm")
      .text((event) => this.truncate(event.title, 42))

    eventGroups
      .append("text")
      .attr("x", 14)
      .attr("y", 12)
      .attr("class", "fill-muted-foreground text-xs")
      .text((event) => `${event.relative_time} / ${event.event_type || "event"}`)
  }

  truncate(value, length) {
    const text = String(value || "")
    if (text.length <= length) return text
    return `${text.slice(0, length - 1)}...`
  }
}
