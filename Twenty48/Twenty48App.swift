import SwiftUI

@main
struct Twenty48App: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

enum Direction { case up, down, left, right }

struct ContentView: View {
    @State private var grid: [[Int]] = ContentView.newGrid()
    @State private var score = 0
    @State private var gameOver = false

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Text("2048").font(.system(size: 40, weight: .heavy, design: .rounded))
                Spacer()
                VStack(spacing: 2) {
                    Text("SCORE").font(.caption.weight(.bold)).foregroundColor(.secondary)
                    Text("\(score)").font(.title2.weight(.bold)).monospacedDigit()
                }
            }
            .padding(.horizontal, 20)

            ZStack {
                VStack(spacing: 10) {
                    ForEach(0..<4, id: \.self) { r in
                        HStack(spacing: 10) {
                            ForEach(0..<4, id: \.self) { c in tile(grid[r][c]) }
                        }
                    }
                }
                .padding(10)
                .background(Color(red: 0.73, green: 0.68, blue: 0.63))
                .cornerRadius(12)

                if gameOver {
                    VStack(spacing: 12) {
                        Text("Game Over").font(.system(size: 38, weight: .heavy, design: .rounded))
                        Text("Score: \(score)").font(.title3.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white.opacity(0.75))
                    .cornerRadius(12)
                    .foregroundColor(.black)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .padding(.horizontal, 16)
            .gesture(DragGesture(minimumDistance: 20).onEnded { v in
                let dx = v.translation.width, dy = v.translation.height
                if abs(dx) > abs(dy) { move(dx > 0 ? .right : .left) }
                else { move(dy > 0 ? .down : .up) }
            })

            Button("Restart", action: restart)
                .font(.title3.weight(.semibold))
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func tile(_ v: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8).fill(Self.color(v))
            if v > 0 {
                Text("\(v)")
                    .font(.system(size: v < 100 ? 36 : v < 1000 ? 30 : 24, weight: .bold, design: .rounded))
                    .foregroundColor(v <= 4 ? Color(red: 0.47, green: 0.43, blue: 0.40) : .white)
                    .minimumScaleFactor(0.5)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    static func color(_ v: Int) -> Color {
        switch v {
        case 0: return Color(red: 0.80, green: 0.76, blue: 0.71)
        case 2: return Color(red: 0.93, green: 0.89, blue: 0.85)
        case 4: return Color(red: 0.93, green: 0.88, blue: 0.78)
        case 8: return Color(red: 0.95, green: 0.69, blue: 0.47)
        case 16: return Color(red: 0.96, green: 0.58, blue: 0.39)
        case 32: return Color(red: 0.96, green: 0.49, blue: 0.37)
        case 64: return Color(red: 0.96, green: 0.37, blue: 0.23)
        case 128: return Color(red: 0.93, green: 0.81, blue: 0.45)
        case 256: return Color(red: 0.93, green: 0.80, blue: 0.38)
        case 512: return Color(red: 0.93, green: 0.78, blue: 0.31)
        case 1024: return Color(red: 0.93, green: 0.77, blue: 0.25)
        case 2048: return Color(red: 0.93, green: 0.76, blue: 0.18)
        default: return Color(red: 0.24, green: 0.23, blue: 0.20)
        }
    }

    static func newGrid() -> [[Int]] {
        var g = Array(repeating: Array(repeating: 0, count: 4), count: 4)
        addTile(&g); addTile(&g)
        return g
    }

    static func addTile(_ g: inout [[Int]]) {
        var empty: [(Int, Int)] = []
        for r in 0..<4 { for c in 0..<4 where g[r][c] == 0 { empty.append((r, c)) } }
        guard let (r, c) = empty.randomElement() else { return }
        g[r][c] = Int.random(in: 0..<10) == 0 ? 4 : 2
    }

    // Slides one row toward index 0, merging equal pairs once.
    static func slide(_ line: [Int]) -> ([Int], Int) {
        let vals = line.filter { $0 != 0 }
        var out: [Int] = []; var gained = 0; var i = 0
        while i < vals.count {
            if i + 1 < vals.count && vals[i] == vals[i + 1] {
                out.append(vals[i] * 2); gained += vals[i] * 2; i += 2
            } else { out.append(vals[i]); i += 1 }
        }
        return (out + Array(repeating: 0, count: 4 - out.count), gained)
    }

    static func apply(_ g: [[Int]], _ dir: Direction) -> ([[Int]], Int) {
        var res = g; var gained = 0
        for i in 0..<4 {
            var line: [Int]
            switch dir {
            case .left: line = g[i]
            case .right: line = g[i].reversed()
            case .up: line = (0..<4).map { g[$0][i] }
            case .down: line = (0..<4).reversed().map { g[$0][i] }
            }
            let (s, p) = slide(line); gained += p
            for j in 0..<4 {
                switch dir {
                case .left: res[i][j] = s[j]
                case .right: res[i][3 - j] = s[j]
                case .up: res[j][i] = s[j]
                case .down: res[3 - j][i] = s[j]
                }
            }
        }
        return (res, gained)
    }

    private func move(_ dir: Direction) {
        guard !gameOver else { return }
        var (next, gained) = Self.apply(grid, dir)
        guard next != grid else { return }
        Self.addTile(&next)
        withAnimation(.easeInOut(duration: 0.12)) {
            grid = next
            score += gained
        }
        let canMove = [Direction.up, .down, .left, .right].contains { Self.apply(next, $0).0 != next }
        if !canMove { gameOver = true }
    }

    private func restart() {
        grid = Self.newGrid()
        score = 0
        gameOver = false
    }
}
