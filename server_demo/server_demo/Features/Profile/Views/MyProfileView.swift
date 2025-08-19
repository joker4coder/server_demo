
//
//  MyProfileView.swift
//  server_demo
//
//  Created by Google on 2025/8/19.
//

import SwiftUI

struct MyProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 1. 个人信息区域 - 包含背景图
                    ZStack(alignment: .bottomLeading) {
                        // 背景图只在此 ZStack 内部显示
                        Image("my-bg")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200) // 背景图的高度
                            .clipped()
                        
                        // 蒙版
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black.opacity(0.1), Color.black.opacity(0.6)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 200)

                        // 个人信息内容
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .bottom, spacing: 16) {
                                Image("player_avatar") // Ensure this image exists in Assets
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 8) {
                                        Text(authViewModel.userProfile?.username ?? "访客")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.white)
                                        PlayerPositionLabel(title: "前腰")
                                        PlayerPositionLabel(title: "右边")
                                        PlayerPositionLabel(title: "右前卫")
                                    }
                                    
                                    Text("所属球队: 深圳夜鹰.深圳种子队")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40) // 调整与卡片间距
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                    .frame(height: 200) // ZStack 的整体高度
                    
                    // 2. 统计数据卡片
                    VStack(spacing: 20) {
                        HStack(spacing: 40) {
                            StatView(number: "766", label: "进球")
                            StatView(number: "68", label: "助攻")
                            StatView(number: "569", label: "出场")
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(color: Color.gray.opacity(0.1), radius: 5, x: 0, y: 5)
                    .padding(.horizontal, 16)
                    .offset(y: -40) // 向上移动，与背景图重叠
                    
                    // 3. 菜单列表
                    VStack(spacing: 0) {
                        MenuListRow(icon: "photo.on.rectangle.angled", title: "个人集锦", subtitle: "已保存至我的视频片段", showChevron: true)
                        //MenuListRow(icon: "flag.fill", title: "我的比赛", subtitle: "仅显示我参加的比赛", showChevron: true)
                        //MenuListRow(icon: "person.fill", title: "球员信息", subtitle: "个人基本信息，公开展示", showChevron: true)
                        //MenuListRow(icon: "lock.shield.fill", title: "实名信息", subtitle: "参加赛事时需进行实名认证", showChevron: true)
                       // MenuListRow(icon: "square.grid.2x2.fill", title: "个人属性", subtitle: "初次加入球队时，此为默认属性", showChevron: true)
                        
                        Divider().padding(.leading, 50)
                        
                        MenuListRow(icon: "list.bullet.rectangle.fill", title: "订单", showChevron: true)
                        MenuListRow(icon: "headphones", title: "客服", showChevron: true)
                        MenuListRow(icon: "gearshape.fill", title: "设置", showChevron: true)
                    }
                    .padding(.horizontal, 16)
                    .offset(y: -40)
                    
                    // 4. Logout Button
                    Button(action: {
                        authViewModel.logout()
                    }) {
                        Text("退出登录")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.2, green: 0.6, blue: 0.1, opacity: 1.0))
                            .cornerRadius(10)
                    }
                    .padding()
                    .offset(y: -40)
                }
            }
            .background(Color(.systemGray6)) // 整个 ScrollView 的背景色
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
