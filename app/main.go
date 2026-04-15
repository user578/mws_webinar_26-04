package main

import (
	"encoding/json"
	"log"
	"math"
	"math/rand"
	"net/http"
	"sync"
	"time"
)

// ========== НАСТРАИВАЕМЫЕ ПАРАМЕТРЫ ==========
const (
	maxPoints   = 20    // максимальное количество точек на графике
	initFill    = 20    // начальное заполнение
	minRate     = 70.0  // мин. курс
	maxRate     = 100.0 // макс. курс
	minQueue    = 0.0   // мин. длина очереди
	maxQueue    = 50.0  // макс. длина очереди
	stepMs      = 750   // интервал обновления (мс)
	port        = "8080"
)

type Point struct {
	X float64 `json:"x"` // длина очереди
	Y float64 `json:"y"` // курс доллара
}

// DataGenerator генерирует точки с паттерном (тренд → боковик → повтор)
type DataGenerator struct {
	mu     sync.RWMutex
	points []Point

	phase          string  // "trend_up", "trend_down", "sideways"
	phaseRemaining int     // сколько точек осталось в фазе
	trendStep      float64 // шаг для тренда
}

func NewDataGenerator() *DataGenerator {
	dg := &DataGenerator{
		points: make([]Point, 0, maxPoints),
	}
	dg.generateInitial()
	return dg
}

func (dg *DataGenerator) generateInitial() {
	dg.mu.Lock()
	defer dg.mu.Unlock()

	dg.initRandomPhase()
	lastX := (minQueue + maxQueue) / 2

	for i := 0; i < initFill; i++ {
		nextX := dg.generateNextX(lastX)
		lastX = nextX

		baseRate := minRate + (nextX/maxQueue)*(maxRate-minRate)
		noise := (rand.Float64() - 0.5) * 2.5
		nextY := baseRate + noise
		nextY = math.Max(minRate, math.Min(maxRate, nextY))
		nextY = math.Round(nextY*100) / 100

		dg.points = append(dg.points, Point{X: nextX, Y: nextY})
	}
}

func (dg *DataGenerator) initRandomPhase() {
	if rand.Intn(2) == 0 {
		dg.phase = "trend_up"
	} else {
		dg.phase = "trend_down"
	}
	dg.phaseRemaining = rand.Intn(6) + 5
	step := 1.5 + rand.Float64()*1.5
	if dg.phase == "trend_down" {
		step = -step
	}
	dg.trendStep = step
}

func (dg *DataGenerator) generateNextX(lastX float64) float64 {
	if dg.phaseRemaining <= 0 {
		if dg.phase == "sideways" {
			if rand.Intn(2) == 0 {
				dg.phase = "trend_up"
			} else {
				dg.phase = "trend_down"
			}
			dg.phaseRemaining = rand.Intn(6) + 5
			step := 1.5 + rand.Float64()*1.5
			if dg.phase == "trend_down" {
				step = -step
			}
			dg.trendStep = step
		} else {
			dg.phase = "sideways"
			dg.phaseRemaining = rand.Intn(3) + 4
		}
	}

	var delta float64
	switch dg.phase {
	case "trend_up", "trend_down":
		delta = dg.trendStep + (rand.Float64()-0.5)*0.8
	case "sideways":
		delta = (rand.Float64() - 0.5) * 2.0
	}

	nextX := lastX + delta
	oldNextX := nextX
	nextX = math.Max(minQueue, math.Min(maxQueue, nextX))

	if dg.phase != "sideways" {
		if (delta > 0 && oldNextX >= maxQueue) || (delta < 0 && oldNextX <= minQueue) {
			dg.phaseRemaining = 0
		}
	}

	dg.phaseRemaining--
	return nextX
}

// Step генерирует следующую точку и обновляет слайс
func (dg *DataGenerator) Step() {
	dg.mu.Lock()
	defer dg.mu.Unlock()

	if len(dg.points) == 0 {
		return
	}
	lastX := dg.points[len(dg.points)-1].X
	nextX := dg.generateNextX(lastX)

	baseRate := minRate + (nextX/maxQueue)*(maxRate-minRate)
	noise := (rand.Float64() - 0.5) * 2.5
	nextY := baseRate + noise
	nextY = math.Max(minRate, math.Min(maxRate, nextY))
	nextY = math.Round(nextY*100) / 100

	newPoint := Point{X: nextX, Y: nextY}
	dg.points = append(dg.points, newPoint)
	if len(dg.points) > maxPoints {
		dg.points = dg.points[1:]
	}
}

// GetPoints возвращает копию текущих точек
func (dg *DataGenerator) GetPoints() []Point {
	dg.mu.RLock()
	defer dg.mu.RUnlock()
	cpy := make([]Point, len(dg.points))
	copy(cpy, dg.points)
	return cpy
}

var dataGen *DataGenerator

// pointsHandler возвращает текущие точки в формате JSON
func pointsHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	points := dataGen.GetPoints()
	if err := json.NewEncoder(w).Encode(points); err != nil {
		log.Printf("JSON encode error: %v", err)
	}
}

func main() {
	rand.Seed(time.Now().UnixNano())
	dataGen = NewDataGenerator()

	// Фоновый генератор данных
	go func() {
		ticker := time.NewTicker(stepMs * time.Millisecond)
		for range ticker.C {
			dataGen.Step()
		}
	}()

	http.HandleFunc("/", serveHome)
	http.HandleFunc("/api/points", pointsHandler)

	log.Printf("Сервер запущен на http://localhost:%s", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}

// serveHome отдаёт HTML-страницу с polling-клиентом
func serveHome(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	html := `<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Cool Business App</title>
    <style>
        body {
            overflow: hidden;
            height: 100vh;
            margin: 0;
            padding: 20px;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(145deg, #1e2a3a 0%, #0f1a24 100%);
            display: flex;
            justify-content: center;
            align-items: center;
        }
        html, body {
            overflow: hidden;
            height: 100%;
        }
        .container {
            background: rgba(255,255,255,0.1);
            backdrop-filter: blur(8px);
            border-radius: 48px;
            padding: 20px 30px 30px 30px;
            box-shadow: 0 25px 45px rgba(0,0,0,0.3);
            border: 1px solid rgba(255,255,255,0.2);
            max-height: 100vh;
            overflow: hidden;
            width: fit-content;
            margin: auto;
        }
        .caption {
            text-align: center;
            margin-top: 16px;
            font-size: 21px;
            font-weight: bold;
            color: #f0e6d0;
            background: #2c3e2f;
            display: inline-block;
            width: auto;
            padding: 6px 20px;
            border-radius: 60px;
            backdrop-filter: blur(4px);
            letter-spacing: 0.5px;
            white-space: nowrap;
        }
        h1 {
            font-size: 64px;
            font-weight: 900;
            text-align: center;
            margin: 0 0 20px 0;
            color: #FFB347;
            text-shadow: 3px 3px 0 #8B4513;
            letter-spacing: 2px;
        }
        .graph-wrapper {
            background: #0b1620;
            border-radius: 28px;
            padding: 20px;
            box-shadow: inset 0 0 8px rgba(0,0,0,0.5), 0 10px 20px rgba(0,0,0,0.2);
        }
        .current-rate-panel {
            background: rgba(0,0,0,0.75);
            backdrop-filter: blur(8px);
            border-radius: 60px;
            padding: 6px 20px;
            margin-bottom: 15px;
            display: inline-block;
            border: 1px solid #FFB347;
            font-size: 28px;
            font-weight: bold;
            color: #FFD966;
            font-family: monospace;
        }
        .current-rate-panel span {
            font-size: 18px;
            color: #ddd;
            font-family: 'Segoe UI', sans-serif;
        }
        canvas {
            display: block;
            margin: 0 auto;
            border-radius: 20px;
            background: #fef9e8;
            box-shadow: 0 4px 12px rgba(0,0,0,0.3);
        }
        .footer {
            display: flex;
            justify-content: center;
            margin-top: 10px;
        }
        .tooltip {
            position: absolute;
            background: rgba(0,0,0,0.8);
            color: #ffd966;
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 14px;
            pointer-events: none;
            font-family: monospace;
            z-index: 100;
        }
    </style>
</head>
<body>
<div class="container">
    <h1>🐱 Cool business app 🐾</h1>
    <div class="graph-wrapper">
        <div style="display: flex; justify-content: space-between; align-items: baseline;">
            <div class="current-rate-panel">
                💵 <span>курс:</span> <span id="rateValue">--.--</span> ₽
            </div>
        </div>
        <canvas id="dollarChart" width="1100" height="450" style="width:1100px;height:450px"></canvas>
        <div class="footer">
            <div class="caption">📈 Зависимость курса $ от суммарной длины очередей в кофейнях у Московской биржи ☕</div>
        </div>
    </div>
</div>

<script>
    const canvas = document.getElementById('dollarChart');
    const ctx = canvas.getContext('2d');
    const width = canvas.width, height = canvas.height;

    const margin = { top: 30, right: 35, bottom: 50, left: 75 };
    const graphWidth = width - margin.left - margin.right;
    const graphHeight = height - margin.top - margin.bottom;

    const minY = 70, maxY = 100;
    let points = [];

    let tooltipDiv = null;

    function createTooltip() {
        if (!tooltipDiv) {
            tooltipDiv = document.createElement('div');
            tooltipDiv.className = 'tooltip';
            document.body.appendChild(tooltipDiv);
        }
    }

    function showTooltip(text, x, y) {
        createTooltip();
        tooltipDiv.style.display = 'block';
        tooltipDiv.innerHTML = text;
        tooltipDiv.style.left = (x + 15) + 'px';
        tooltipDiv.style.top = (y - 25) + 'px';
    }

    function hideTooltip() {
        if (tooltipDiv) tooltipDiv.style.display = 'none';
    }

    function mapX(index, total) {
        return margin.left + (index / (total - 1)) * graphWidth;
    }

    function mapY(value) {
        return margin.top + graphHeight - ((value - minY) / (maxY - minY)) * graphHeight;
    }

    function drawAxes() {
        ctx.save();
        ctx.strokeStyle = '#4a5b6e';
        ctx.fillStyle = '#1f2a36';
        ctx.font = '12px "Segoe UI", monospace';
        ctx.lineWidth = 1;

        ctx.beginPath();
        ctx.moveTo(margin.left, margin.top);
        ctx.lineTo(margin.left, margin.top + graphHeight);
        ctx.lineTo(margin.left + graphWidth, margin.top + graphHeight);
        ctx.stroke();

        for (let v = 70; v <= 100; v += 5) {
            const y = mapY(v);
            ctx.fillStyle = '#2c3e50';
            ctx.fillText(v + ' ₽', margin.left - 38, y + 4);
            ctx.beginPath();
            ctx.strokeStyle = '#cbd5e1';
            ctx.setLineDash([4, 6]);
            ctx.moveTo(margin.left, y);
            ctx.lineTo(margin.left + graphWidth, y);
            ctx.stroke();
        }
        ctx.setLineDash([]);

        ctx.save();
        ctx.translate(28, margin.top + graphHeight/2);
        ctx.rotate(-Math.PI/2);
        ctx.fillStyle = '#2d3e4b';
        ctx.font = 'bold 14px "Segoe UI"';
        ctx.fillText('Курс (руб за $)', 0, 0);
        ctx.restore();

        ctx.fillStyle = '#2d3e4b';
        ctx.font = 'bold 12px "Segoe UI"';
        ctx.fillText('→ Длина очереди (человек)', margin.left + graphWidth - 160, margin.top + graphHeight + 38);
    }

    function drawCatsAndLabels() {
        const n = points.length;
        if (n === 0) return;

        ctx.font = '20px "Segoe UI Emoji", "Apple Color Emoji", "Noto Color Emoji", sans-serif';
        ctx.shadowBlur = 0;

        for (let i = 0; i < n; i++) {
            const x = mapX(i, n);
            const y = mapY(points[i].y);
            ctx.fillStyle = '#000000';
            ctx.fillText('😺', x - 7, y + 6);
        }

        if (n > 0) {
            const lastIdx = n-1;
            const lastX = mapX(lastIdx, n);
            const lastY = mapY(points[lastIdx].y);
            ctx.font = 'bold 14px "Segoe UI"';
            ctx.fillStyle = '#c4450c';
            ctx.fillText(points[lastIdx].y.toFixed(2) + ' ₽', lastX - 28, lastY - 12);
        }

        ctx.font = '12px "Segoe UI", monospace';
        for (let i = 0; i < n; i++) {
            const x = mapX(i, n);
            const queueVal = points[i].x.toFixed(0);
            let color = '#1f4a2c';
            if (i > 0) {
                const prevQueue = points[i-1].x;
                if (queueVal > prevQueue) color = '#d32f2f';
                else if (queueVal < prevQueue) color = '#2e7d32';
            }
            ctx.fillStyle = color;
            ctx.fillText(queueVal, x - 8, margin.top + graphHeight + 22);
        }
    }

    function drawChart() {
        if (!points.length) return;
        ctx.clearRect(0, 0, width, height);
        drawAxes();

        const n = points.length;
        if (n > 1) {
            ctx.beginPath();
            ctx.strokeStyle = '#e67e22';
            ctx.lineWidth = 2.5;
            ctx.lineJoin = 'round';
            ctx.lineCap = 'round';
            for (let i = 0; i < n; i++) {
                const x = mapX(i, n);
                const y = mapY(points[i].y);
                if (i === 0) ctx.moveTo(x, y);
                else ctx.lineTo(x, y);
            }
            ctx.stroke();
        }

        drawCatsAndLabels();

        canvas.onmousemove = function(e) {
            const rect = canvas.getBoundingClientRect();
            const scaleX = canvas.width / rect.width;
            const scaleY = canvas.height / rect.height;
            const mouseX = (e.clientX - rect.left) * scaleX;
            const mouseY = (e.clientY - rect.top) * scaleY;
            if (points.length === 0) return;
            for (let i = 0; i < points.length; i++) {
                const x = mapX(i, points.length);
                const y = mapY(points[i].y);
                const dist = Math.hypot(mouseX - x, mouseY - y);
                if (dist < 14) {
                    showTooltip('🧑‍🤝‍🧑 очередь: ' + points[i].x.toFixed(0) + ' чел.', e.clientX, e.clientY);
                    return;
                }
            }
            hideTooltip();
        };
        canvas.onmouseleave = function() { hideTooltip(); };
    }

    function updateCurrentRateDisplay(rate) {
        document.getElementById('rateValue').innerText = rate.toFixed(2);
    }

    // HTTP polling вместо WebSocket
    function pollData() {
        fetch('/api/points')
            .then(response => response.json())
            .then(newPoints => {
                points = newPoints;
                drawChart();
                if (points.length > 0) updateCurrentRateDisplay(points[points.length-1].y);
            })
            .catch(err => console.error('Polling error:', err));
    }

    // Опрашиваем каждые 750 мс (синхронизировано с шагом генерации)
    setInterval(pollData, 750);
    pollData(); // немедленный первый запрос

    window.addEventListener('resize', () => drawChart());
</script>
</body>
</html>`
	w.Write([]byte(html))
}