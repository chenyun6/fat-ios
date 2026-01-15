//
//  AppleStyleFeedback.swift
//  fat - Apple 风格烟花效果
//
//  Created by Hello World on 2026/1/12.
//

import SwiftUI

// MARK: - Apple 风格烟花效果
struct AppleStyleFeedback: View {
    let id: UUID
    let centerX: CGFloat
    let centerY: CGFloat
    let isPositive: Bool
    @State private var particles: [FireworkParticle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [particle.color, particle.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: particle.size, height: particle.size)
                    .blur(radius: particle.size * 0.2)
                    .position(particle.position)
                    .opacity(particle.opacity)
                    .shadow(
                        color: particle.color.opacity(0.4),
                        radius: particle.size * 0.5
                    )
            }
        }
        .onAppear {
            generateParticles()
            animateParticles()
        }
    }
    
    private func generateParticles() {
        // Apple 风格的颜色方案：柔和、优雅
        let colorSchemes: [[Color]] = isPositive ? [
            [.green, .mint, .teal],
            [.mint, .cyan, .blue],
            [.yellow, .green, .mint],
            [.green, .teal, .cyan]
        ] : [
            [.orange, .yellow, .pink],
            [.pink, .red, .orange],
            [.yellow, .orange, .red],
            [.orange, .pink, .red]
        ]
        
        let selectedColors = colorSchemes.randomElement() ?? (isPositive ? [.green, .mint] : [.orange, .yellow])
        let particleCount = Int.random(in: 30...45)  // Apple风格：适中的粒子数量
        let pattern = Int.random(in: 0...2)
        
        particles = (0..<particleCount).map { index in
            let angle: Double
            let distance: Double
            
            switch pattern {
            case 0:
                // 圆形扩散
                angle = Double(index) / Double(particleCount) * 2 * .pi + Double.random(in: -0.15...0.15)
                distance = Double.random(in: 80...200)
            case 1:
                // 分组扩散
                let group = index % 8
                angle = Double(group) / 8.0 * 2 * .pi + Double.random(in: -0.1...0.1)
                distance = Double.random(in: 100...220)
            default:
                // 随机扩散
                angle = Double.random(in: 0...(2 * .pi))
                distance = Double.random(in: 60...180)
            }
            
            let size = Double.random(in: 6...12)  // Apple风格：适中的粒子大小
            let color = selectedColors.randomElement() ?? (isPositive ? .green : .orange)
            
            return FireworkParticle(
                id: UUID(),
                position: CGPoint(x: centerX, y: centerY),
                targetPosition: CGPoint(
                    x: centerX + cos(angle) * distance,
                    y: centerY + sin(angle) * distance
                ),
                color: color,
                size: size,
                opacity: 1.0
            )
        }
    }
    
    private func animateParticles() {
        // Apple风格：使用Spring动画，流畅自然
        withAnimation(.spring(response: 1.0, dampingFraction: 0.6)) {
            for index in particles.indices {
                particles[index].position = particles[index].targetPosition
            }
        }
        
        // 淡出动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.8)) {
                for index in particles.indices {
                    particles[index].opacity = 0
                }
            }
        }
    }
}

struct FireworkParticle: Identifiable {
    let id: UUID
    var position: CGPoint
    let targetPosition: CGPoint
    let color: Color
    let size: CGFloat
    var opacity: Double
}
