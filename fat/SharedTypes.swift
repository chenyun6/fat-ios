//
//  SharedTypes.swift
//  fat
//
//  Created by Hello World on 2026/1/12.
//

import SwiftUI

// MARK: - 体重选项枚举
enum WeightOption {
    case fat
    case notFat
}

// MARK: - 粒子结构
struct Particle: Identifiable {
    let id: UUID
    var position: CGPoint
    let targetPosition: CGPoint
    let color: Color
    let size: CGFloat
    var opacity: Double
}

// MARK: - Apple 风格按钮组件
struct AppleStyleButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            action()
        }) {
            HStack(spacing: 20) {
                // 图标
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [color, color.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                
                // 文字内容
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 24, weight: .semibold, design: .default))
                        .foregroundColor(.primary)
                        .tracking(-0.3)
                    
                    Text(subtitle)
                        .font(.system(size: 15, weight: .regular, design: .default))
                        .foregroundColor(.secondary)
                        .tracking(0.1)
                }
                
                Spacer()
                
                // 选中指示器
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(color)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        Material.ultraThinMaterial
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isSelected ? color.opacity(0.5) : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
            .shadow(
                color: isSelected ? color.opacity(0.2) : (colorScheme == .dark ? Color.clear : Color.black.opacity(0.05)),
                radius: isSelected ? 20 : (colorScheme == .dark ? 0 : 10),
                x: 0,
                y: isSelected ? 10 : (colorScheme == .dark ? 0 : 5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

// MARK: - 烟花视图
struct FireworksView: View {
    let id: UUID
    let centerX: CGFloat
    let centerY: CGFloat
    let isPositive: Bool
    @State private var particles: [Particle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [particle.color, particle.color.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: particle.size, height: particle.size)
                    .blur(radius: particle.size * 0.3)
                    .position(particle.position)
                    .opacity(particle.opacity)
            }
        }
        .onAppear {
            generateParticles()
            animateParticles()
        }
    }
    
    private func generateParticles() {
        let colorSchemes: [[Color]] = isPositive ? [
            [.green, .mint, .teal],
            [.mint, .cyan, .blue],
            [.yellow, .green, .mint]
        ] : [
            [.orange, .yellow, .pink],
            [.pink, .red, .orange],
            [.yellow, .orange, .red]
        ]
        
        let selectedColors = colorSchemes.randomElement() ?? (isPositive ? [.green, .mint] : [.orange, .yellow])
        let particleCount = Int.random(in: 50...70)
        let pattern = Int.random(in: 0...2)
        
        particles = (0..<particleCount).map { index in
            let angle: Double
            let distance: Double
            
            switch pattern {
            case 0:
                angle = Double(index) / Double(particleCount) * 2 * .pi + Double.random(in: -0.2...0.2)
                distance = Double.random(in: 100...280)
            case 1:
                let group = index % 10
                angle = Double(group) / 10.0 * 2 * .pi + Double.random(in: -0.1...0.1)
                distance = Double.random(in: 120...300)
            default:
                angle = Double.random(in: 0...(2 * .pi))
                distance = Double.random(in: 80...260)
            }
            
            let size = Double.random(in: 8...18)
            let color = selectedColors.randomElement() ?? (isPositive ? .green : .orange)
            
            return Particle(
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
        withAnimation(.spring(response: 1.2, dampingFraction: 0.5)) {
            for index in particles.indices {
                particles[index].position = particles[index].targetPosition
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.9)) {
                for index in particles.indices {
                    particles[index].opacity = 0
                }
            }
        }
    }
}
