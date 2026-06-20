import { Controller } from "@hotwired/stimulus"
import * as d3 from "d3"

export default class extends Controller {
  static targets = ["svg"]
  static values = {
    data: Array,
    type: String,
    xKey: String,
    yKey: String,
    labelKey: String,
    valueKey: String,
  }

  connect() {
    this.resizeObserver = new ResizeObserver(() => this.render())
    this.resizeObserver.observe(this.element)
    this.render()
  }

  disconnect() {
    if (this.resizeObserver) this.resizeObserver.disconnect()
  }

  render() {
    if (!this.hasSvgTarget) return

    const svg = d3.select(this.svgTarget)
    svg.selectAll("*").remove()

    const bounds = this.dimensions()
    if (bounds.width <= 0 || bounds.height <= 0) return

    if (this.typeValue === "pie") {
      this.renderPie(svg, bounds)
    } else if (this.typeValue === "area") {
      this.renderCartesian(svg, bounds, { area: true })
    } else if (this.typeValue === "line") {
      this.renderCartesian(svg, bounds, { line: true })
    } else {
      this.renderCartesian(svg, bounds, { bars: true })
    }
  }

  renderCartesian(svg, bounds, mode) {
    const data = this.seriesData()
    const margin = { top: 10, right: 14, bottom: 34, left: 42 }
    const innerWidth = bounds.width - margin.left - margin.right
    const innerHeight = bounds.height - margin.top - margin.bottom
    const x = d3.scaleBand()
      .domain(data.map((item) => item.label))
      .range([0, innerWidth])
      .padding(mode.bars ? 0.22 : 0.08)
    const y = d3.scaleLinear()
      .domain([0, d3.max(data, (item) => item.value) || 1])
      .nice()
      .range([innerHeight, 0])
    const g = svg.append("g").attr("transform", `translate(${margin.left},${margin.top})`)

    this.drawAxes(g, x, y, innerHeight)

    if (mode.bars) this.drawBars(g, data, x, y, innerHeight)
    if (mode.area) this.drawArea(g, data, x, y, innerHeight)
    if (mode.line) this.drawLine(g, data, x, y)
  }

  renderPie(svg, bounds) {
    const data = this.pieData()
    const radius = Math.min(bounds.width, bounds.height) / 2 - 14
    const g = svg.append("g").attr("transform", `translate(${bounds.width / 2},${bounds.height / 2})`)
    const color = d3.scaleOrdinal()
      .domain(data.map((item) => item.label))
      .range(["hsl(var(--primary))", "hsl(var(--secondary))", "hsl(var(--accent))", "hsl(var(--muted))", "hsl(var(--destructive))"])
    const arc = d3.arc().innerRadius(0).outerRadius(radius)
    const labelArc = d3.arc().innerRadius(radius * 0.62).outerRadius(radius * 0.62)
    const pie = d3.pie().value((item) => item.value).sort(null)

    g.selectAll("path")
      .data(pie(data))
      .join("path")
      .attr("d", arc)
      .attr("fill", (item) => color(item.data.label))
      .attr("stroke", "hsl(var(--border))")
      .attr("stroke-width", 2)

    g.selectAll("text")
      .data(pie(data).filter((item) => item.endAngle - item.startAngle > 0.35))
      .join("text")
      .attr("transform", (item) => `translate(${labelArc.centroid(item)})`)
      .attr("text-anchor", "middle")
      .attr("dominant-baseline", "middle")
      .attr("class", "fill-foreground text-xs font-bold")
      .text((item) => item.data.label)
  }

  drawAxes(g, x, y, height) {
    g.append("g")
      .attr("transform", `translate(0,${height})`)
      .call(d3.axisBottom(x).tickSizeOuter(0))
      .call((axis) => axis.selectAll("path,line").attr("stroke", "hsl(var(--border))").attr("stroke-width", 2))
      .call((axis) => axis.selectAll("text").attr("class", "fill-foreground text-xs"))

    g.append("g")
      .call(d3.axisLeft(y).ticks(4).tickSizeOuter(0))
      .call((axis) => axis.selectAll("path,line").attr("stroke", "hsl(var(--border))").attr("stroke-width", 2))
      .call((axis) => axis.selectAll("text").attr("class", "fill-foreground text-xs"))
  }

  drawBars(g, data, x, y, height) {
    g.selectAll("rect")
      .data(data)
      .join("rect")
      .attr("x", (item) => x(item.label))
      .attr("y", (item) => y(item.value))
      .attr("width", x.bandwidth())
      .attr("height", (item) => height - y(item.value))
      .attr("fill", "hsl(var(--primary))")
      .attr("stroke", "hsl(var(--border))")
      .attr("stroke-width", 2)
  }

  drawArea(g, data, x, y, height) {
    const area = d3.area()
      .x((item) => this.bandCenter(x, item.label))
      .y0(height)
      .y1((item) => y(item.value))
      .curve(d3.curveMonotoneX)

    g.append("path")
      .datum(data)
      .attr("d", area)
      .attr("fill", "hsl(var(--primary) / 0.35)")
      .attr("stroke", "hsl(var(--border))")
      .attr("stroke-width", 2)
  }

  drawLine(g, data, x, y) {
    const line = d3.line()
      .x((item) => this.bandCenter(x, item.label))
      .y((item) => y(item.value))
      .curve(d3.curveMonotoneX)

    g.append("path")
      .datum(data)
      .attr("d", line)
      .attr("fill", "none")
      .attr("stroke", "hsl(var(--primary))")
      .attr("stroke-width", 3)

    g.selectAll("circle")
      .data(data)
      .join("circle")
      .attr("cx", (item) => this.bandCenter(x, item.label))
      .attr("cy", (item) => y(item.value))
      .attr("r", 4)
      .attr("fill", "hsl(var(--background))")
      .attr("stroke", "hsl(var(--border))")
      .attr("stroke-width", 2)
  }

  dimensions() {
    const viewBox = this.svgTarget.getAttribute("viewBox").split(/\s+/).map(Number)
    const width = Math.max(this.svgTarget.clientWidth || viewBox[2], 1)
    const height = Math.max(Number(this.svgTarget.getAttribute("height")) || viewBox[3], 1)
    this.svgTarget.setAttribute("viewBox", `0 0 ${width} ${height}`)
    return { width, height }
  }

  seriesData() {
    return this.dataValue.map((item) => ({
      label: String(item[this.xKeyValue]),
      value: Number(item[this.yKeyValue]) || 0,
    }))
  }

  pieData() {
    return this.dataValue.map((item) => ({
      label: String(item[this.labelKeyValue]),
      value: Number(item[this.valueKeyValue]) || 0,
    }))
  }

  bandCenter(scale, label) {
    return scale(label) + scale.bandwidth() / 2
  }
}
