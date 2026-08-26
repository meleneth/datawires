import { Controller } from "@hotwired/stimulus"
import * as d3 from "d3"

export default class extends Controller {
  static targets = ["chart"]
  static values = { points: Array, renderer: String, unit: String }

  connect() {
    this.render()
  }

  render() {
    const points = this.pointsValue.map((point) => ({ time: new Date(point.time), value: Number(point.value) }))
    const width = Math.max(this.chartTarget.clientWidth, 240)
    const height = 140
    this.chartTarget.replaceChildren()
    const svg = d3.select(this.chartTarget).append("svg").attr("viewBox", `0 0 ${width} ${height}`).attr("class", "h-full w-full")
    if (points.length === 0) return
    const x = d3.scaleTime().domain(d3.extent(points, (point) => point.time)).range([8, width - 8])
    const extent = d3.extent(points, (point) => point.value)
    const yDomain = extent[0] === extent[1] ? [extent[0] - 1, extent[1] + 1] : extent
    const y = d3.scaleLinear().domain(yDomain).nice().range([height - 12, 8])
    if (this.rendererValue === "bar") {
      const barWidth = Math.max(2, (width - 16) / points.length - 2)
      svg.selectAll("rect").data(points).join("rect")
        .attr("x", (point) => x(point.time) - barWidth / 2).attr("y", (point) => y(point.value))
        .attr("width", barWidth).attr("height", (point) => Math.max(1, height - 12 - y(point.value)))
        .attr("class", "fill-primary stroke-black")
    } else if (this.rendererValue === "area") {
      const area = d3.area().x((point) => x(point.time)).y0(height - 12).y1((point) => y(point.value))
      svg.append("path").datum(points).attr("d", area).attr("class", "fill-primary/40 stroke-primary").attr("stroke-width", 2)
    } else {
      const line = d3.line().x((point) => x(point.time)).y((point) => y(point.value))
      svg.append("path").datum(points).attr("d", line).attr("fill", "none").attr("class", "stroke-primary").attr("stroke-width", this.rendererValue === "sparkline" ? 3 : 2)
    }
    svg.selectAll("circle").data(points).join("circle").attr("cx", (point) => x(point.time)).attr("cy", (point) => y(point.value)).attr("r", 3).attr("class", "fill-primary stroke-black")
  }
}
