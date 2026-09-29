const DOT_RADIUS = 3
const HIGHLIGHT_RADIUS = 7
const HIT_RADIUS = 8
const DOT_FILL = "rgba(2, 132, 199, 0.6)"
const HIGHLIGHT_STROKE = "#0284c7"

function lineEl(text) {
  const div = document.createElement("div")
  div.textContent = text
  return div
}

const ChartDots = {
  mounted() {
    this.dots = []
    this.selected = null
    this.chartWidth = parseFloat(this.el.dataset.chartWidth)
    this.chartHeight = parseFloat(this.el.dataset.chartHeight)
    this.xLabel = this.el.dataset.xLabel
    this.tooltip = null

    // Non-responsive charts (breed) get no server-set CSS width, so their
    // layout box defaults to the width/height content attributes. Those
    // are the same attributes draw() rewrites on every call, so without
    // a pin, cssScale() would read back our own previous output and
    // compound on every redraw. Pin once, here, before the first draw().
    // Responsive charts already have style="width: 100%; height: auto;"
    // from the server (a non-empty this.el.style.width), so this guard
    // skips them and they keep tracking their container width via CSS.
    if (!this.el.style.width) {
      this.el.style.width = `${this.chartWidth}px`
      this.el.style.height = `${this.chartHeight}px`
    }

    fetch(this.el.dataset.dotsUrl)
      .then(response => {
        if (!response.ok) throw new Error(`Failed to fetch dots: ${response.status}`)
        return response.json()
      })
      .then(dots => {
        this.dots = dots
        this.draw()
      })
      .catch(error => console.error(error))

    this.el.addEventListener("click", event => this.handleClick(event))

    this.handleScroll = () => {
      this.selected = null
      this.hideTooltip()
    }
    window.addEventListener("scroll", this.handleScroll, { passive: true })
  },

  destroyed() {
    if (this.tooltip) this.tooltip.remove()
    window.removeEventListener("scroll", this.handleScroll)
  },

  // Ratio between the canvas's rendered CSS width and its logical/server
  // width (chartWidth). 1 for non-responsive charts; smaller than 1 when
  // a responsive chart's container is narrower than its intrinsic size.
  cssScale() {
    const rect = this.el.getBoundingClientRect()
    return rect.width / this.chartWidth
  },

  // Draws at the canvas's current rendered size every time. There is no
  // resize listener, so for responsive charts a browser window resize
  // after the first draw will visually stretch the existing bitmap
  // until the next click triggers a redraw at the new size. Accepted
  // trade off: this is an internal spot check tool, not expected to be
  // actively resized while open. Non-responsive charts are pinned to a
  // fixed CSS size in mounted(), so this does not apply to them.
  draw() {
    const dpr = window.devicePixelRatio || 1
    const scale = this.cssScale()

    this.el.width = Math.round(this.chartWidth * scale * dpr)
    this.el.height = Math.round(this.chartHeight * scale * dpr)

    const ctx = this.el.getContext("2d")
    ctx.setTransform(scale * dpr, 0, 0, scale * dpr, 0, 0)

    this.dots.forEach(dot => {
      ctx.beginPath()
      ctx.arc(dot.x, dot.y, DOT_RADIUS, 0, Math.PI * 2)
      ctx.fillStyle = DOT_FILL
      ctx.fill()
    })

    if (this.selected) {
      ctx.beginPath()
      ctx.arc(this.selected.x, this.selected.y, HIGHLIGHT_RADIUS, 0, Math.PI * 2)
      ctx.strokeStyle = HIGHLIGHT_STROKE
      ctx.lineWidth = 2
      ctx.stroke()
    }
  },

  handleClick(event) {
    const rect = this.el.getBoundingClientRect()
    const scale = this.cssScale()
    const x = (event.clientX - rect.left) / scale
    const y = (event.clientY - rect.top) / scale

    const nearest = this.nearestDot(x, y)

    if (this.selected && nearest && nearest.id === this.selected.id) {
      this.selected = null
      this.hideTooltip()
    } else if (nearest) {
      this.selected = nearest
      this.showTooltip(nearest, event.clientX, event.clientY)
    } else {
      this.selected = null
      this.hideTooltip()
    }

    this.draw()
  },

  nearestDot(x, y) {
    let closest = null
    let closestDistance = HIT_RADIUS

    this.dots.forEach(dot => {
      const distance = Math.hypot(dot.x - x, dot.y - y)
      if (distance <= closestDistance) {
        closest = dot
        closestDistance = distance
      }
    })

    return closest
  },

  showTooltip(dot, clientX, clientY) {
    const tooltip = this.tooltipElement()
    tooltip.replaceChildren(
      lineEl(`${dot.name} (ID: ${dot.id})`),
      lineEl(`${this.xLabel}: ${dot.category}`),
      lineEl(`Days to Adoption: ${dot.days}`)
    )
    tooltip.style.left = `${clientX + 8}px`
    tooltip.style.top = `${clientY - 8}px`
    tooltip.hidden = false
  },

  hideTooltip() {
    if (this.tooltip) this.tooltip.hidden = true
  },

  tooltipElement() {
    if (!this.tooltip) {
      this.tooltip = document.createElement("div")
      this.tooltip.className =
        "fixed z-50 rounded bg-slate-900/95 px-2 py-1.5 text-xs text-white shadow-lg pointer-events-none"
      this.tooltip.hidden = true
      document.body.appendChild(this.tooltip)
    }

    return this.tooltip
  }
}

export default ChartDots
