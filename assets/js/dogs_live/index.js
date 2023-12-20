window.addEventListener("phx:DogsLive.Index.init", (event) => {
  // console.debug('phx:DogsLive.Index.init')
  // console.debug(event)

  const detail = event.detail
  // console.debug({detail})

  drawDogSpark(detail.latest_counts)
})


function drawDogSpark(counts) {
  const canvas = document.getElementById("dog-spark")
  const ctx = canvas.getContext("2d")

  const { width, height } = canvas.getBoundingClientRect()
  const max = Math.max(...counts.map(c => c.count))
  const numBars = counts.length
  const gapX = 4
  const numGaps = numBars - 1
  const effectiveW = width - (numGaps * gapX)
  const barW = effectiveW / numBars
  let barH = 0
  
  let x = 0
  let y = 0
  counts.forEach(({count, count_at}) => {
    barH = (count / max) * height
    y = height - barH

    // text-sky-500
    // ctx.fillStyle = "rgba(14, 165, 233, 0.7)"

    // text-orange-400
    ctx.fillStyle = "rgba(251, 146, 60, 0.70)"

    ctx.fillRect(x, y, barW, barH)

    x += barW + gapX
  })
}
