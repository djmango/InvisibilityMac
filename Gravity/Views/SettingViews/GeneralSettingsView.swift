//
//  GeneralSettingsView.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/9/24.
//

import SwiftUI

struct GeneralSettingsView: View {
    var body: some View {
        VStack(spacing: 20) {
          VStack(spacing: 0) {
            HStack(spacing: 0) {
              HStack(spacing: 8) {
                Rectangle()
                  .foregroundColor(.clear)
                  .frame(width: 12, height: 12)
                  .background(Color(red: 1, green: 0.37, blue: 0.34))
                  .cornerRadius(100)
                  .overlay(
                    RoundedRectangle(cornerRadius: 100)
                      .inset(by: 0.25)
                      .stroke(
                        Color(red: 0, green: 0, blue: 0).opacity(0.20), lineWidth: 0.25
                      )
                  )
                Rectangle()
                  .foregroundColor(.clear)
                  .frame(width: 12, height: 12)
                  .background(Color(red: 0.98, green: 0.74, blue: 0.02))
                  .cornerRadius(100)
                  .overlay(
                    RoundedRectangle(cornerRadius: 100)
                      .inset(by: 0.25)
                      .stroke(
                        Color(red: 0, green: 0, blue: 0).opacity(0.20), lineWidth: 0.25
                      )
                  )
                Rectangle()
                  .foregroundColor(.clear)
                  .frame(width: 12, height: 12)
                  .background(Color(red: 0.36, green: 0.36, blue: 0.37))
                  .cornerRadius(100)
                  .overlay(
                    RoundedRectangle(cornerRadius: 100)
                      .inset(by: 0.25)
                      .stroke(
                        Color(red: 0, green: 0, blue: 0).opacity(0.20), lineWidth: 0.25
                      )
                  )
                  .opacity(0)
              }
              .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
              .frame(width: 68)
              HStack(spacing: 0) {
                Text("General")
                      .font(Font.custom("SF Pro", size: 13).weight(Font.Weight.regular))
                  .lineSpacing(16)
                  .foregroundColor(Color(red: 1, green: 1, blue: 1).opacity(0.85))
              }
              .padding(EdgeInsets(top: 3, leading: 10, bottom: 3, trailing: 10))
              .frame(maxWidth: .infinity, minHeight: 22, maxHeight: 22)
            }
            .padding(EdgeInsets(top: 3, leading: 0, bottom: 3, trailing: 68))
            .frame(maxWidth: .infinity)
            HStack(spacing: 2) {
              VStack(spacing: 2) {
                Text("􀍟")
                  .font(Font.custom("SF Pro", size: 20).weight(Font.Weight.regular))
                  .lineSpacing(22)
                  .foregroundColor(Color(red: 0, green: 0.48, blue: 1))
                Text("General")
                  .font(Font.custom("SF Pro", size: 11).weight(Font.Weight.regular))
                  .lineSpacing(14)
                  .foregroundColor(Color(red: 0, green: 0.48, blue: 1))
              }
              .padding(EdgeInsets(top: 3.50, leading: 8, bottom: 3.50, trailing: 8))
              .frame(maxHeight: .infinity)
              .background(Color(red: 1, green: 1, blue: 1).opacity(0.05))
              .cornerRadius(6)
              VStack(spacing: 2) {
                Text("􀎠")
                  .font(Font.custom("SF Pro", size: 20).weight(Font.Weight.regular))
                  .lineSpacing(22)
                  .foregroundColor(Color(red: 1, green: 1, blue: 1).opacity(0.85))
                Text("Security")
                      .font(Font.custom("SF Pro", size: 11).weight(.regular))
                  .lineSpacing(14)
                  .foregroundColor(Color(red: 1, green: 1, blue: 1).opacity(0.85))
              }
              .padding(EdgeInsets(top: 3.50, leading: 8, bottom: 3.50, trailing: 8))
              .frame(maxHeight: .infinity)
              .cornerRadius(6)
              VStack(spacing: 2) {
                Text("􁅏")
                  .font(Font.custom("SF Pro", size: 20).weight(Font.Weight.regular))
                  .lineSpacing(22)
                  .foregroundColor(Color(red: 1, green: 1, blue: 1).opacity(0.85))
                Text("Analytics")
                  .font(Font.custom("SF Pro", size: 11).weight(Font.Weight.regular))
                  .lineSpacing(14)
                  .foregroundColor(Color(red: 1, green: 1, blue: 1).opacity(0.85))
              }
              .padding(EdgeInsets(top: 3.50, leading: 8, bottom: 3.50, trailing: 8))
              .frame(maxHeight: .infinity)
              .cornerRadius(6)
              VStack(spacing: 2) {
                Text("􀥎")
                  .font(Font.custom("SF Pro", size: 20).weight(Font.Weight.regular))
                  .lineSpacing(22)
                  .foregroundColor(Color(red: 1, green: 1, blue: 1).opacity(0.85))
                Text("Advanced")
                  .font(Font.custom("SF Pro", size: 11).weight(Font.Weight.regular))
                  .lineSpacing(14)
                  .foregroundColor(Color(red: 1, green: 1, blue: 1).opacity(0.85))
              }
              .padding(EdgeInsets(top: 3.50, leading: 8, bottom: 3.50, trailing: 8))
              .frame(maxHeight: .infinity)
              .cornerRadius(6)
              VStack(spacing: 2) {
                Text("􀅴")
                  .font(Font.custom("SF Pro", size: 20).weight(Font.Weight.regular))
                  .lineSpacing(22)
                  .foregroundColor(Color(red: 1, green: 1, blue: 1).opacity(0.85))
                Text("About")
                  .font(Font.custom("SF Pro", size: 11).weight(Font.Weight.regular))
                  .lineSpacing(14)
                  .foregroundColor(Color(red: 1, green: 1, blue: 1).opacity(0.85))
              }
              .padding(EdgeInsets(top: 3.50, leading: 8, bottom: 3.50, trailing: 8))
              .frame(maxHeight: .infinity)
              .cornerRadius(6)
            }
          }
          .padding(EdgeInsets(top: 0, leading: 0, bottom: 6, trailing: 0))
          .frame(maxWidth: .infinity, minHeight: 79, maxHeight: 79)
          .background(Color(red: 0.24, green: 0.24, blue: 0.24).opacity(0.80))
          .shadow(
            color: Color(red: 0, green: 0, blue: 0, opacity: 0.10), radius: 5, y: 3
          )
          VStack(spacing: 16) {
            HStack(spacing: 17) {
              Text("Email:")
                .font(Font.custom("SF Pro", size: 13).weight(.bold))
                .lineSpacing(16)
                .foregroundColor(Color(red: 1, green: 1, blue: 1).opacity(0.85))
              VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                  HStack(alignment: .top, spacing: 10) {
                    Text("tye@grav.ai")
                      .font(Font.custom("SF Pro", size: 13).weight(Font.Weight.regular))
                      .lineSpacing(14)
                      .foregroundColor(Color(red: 1, green: 1, blue: 1).opacity(0.85))
                    Text("􀁡")
                      .font(Font.custom("SF Pro", size: 13))
                      .lineSpacing(16)
                      .foregroundColor(Color(red: 1, green: 1, blue: 1).opacity(0.85))
                  }
                  .padding(EdgeInsets(top: 3, leading: 7, bottom: 3, trailing: 7))
                  .frame(width: 150, height: 22)
                  .background(Color(red: 0.16, green: 0.18, blue: 0.18))
                  .cornerRadius(5)
                  .shadow(
                    color: Color(red: 0, green: 0, blue: 0, opacity: 0.30), radius: 2.50, y: 0.50
                  )
                  VStack(spacing: 0) {
                    Text("Sign Out")
                      .font(Font.custom("SF Pro", size: 13))
                      .lineSpacing(1)
                      .foregroundColor(Color(red: 1, green: 1, blue: 1).opacity(0.85))
                  }
                  .padding(EdgeInsets(top: 3, leading: 7, bottom: 3, trailing: 7))
                  .frame(width: 64, height: 20)
                  .background(Color(red: 1, green: 1, blue: 1).opacity(0.25))
                  .cornerRadius(5)
                }
              }
              .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
            VStack(alignment: .trailing, spacing: 10) {
              Rectangle()
                .foregroundColor(.clear)
                .frame(width: 408, height: 1)
                .background(Color(red: 0.85, green: 0.85, blue: 0.85).opacity(0.15))
            }
            .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
            .frame(maxWidth: .infinity, minHeight: 1, maxHeight: 1)
            HStack(alignment: .top, spacing: 17) {
              Text("Summon Chat:")
                .font(Font.custom("SF Pro", size: 13).weight(.bold))
                .lineSpacing(16)
                .foregroundColor(Color(red: 1, green: 1, blue: 1).opacity(0.85))
              VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                  Text("⌥⌥")
                    .font(Font.custom("SF Pro", size: 13))
                    .lineSpacing(16)
                    .foregroundColor(Color(red: 1, green: 1, blue: 1).opacity(0.85))
                  Text("􀁡")
                    .font(Font.custom("SF Pro", size: 13))
                    .lineSpacing(16)
                    .foregroundColor(Color(red: 1, green: 1, blue: 1).opacity(0.85))
                }
                .padding(EdgeInsets(top: 3, leading: 7, bottom: 3, trailing: 6))
                .frame(width: 128, height: 20)
                .background(Color(red: 0.16, green: 0.18, blue: 0.18))
                .cornerRadius(5)
                .shadow(
                  color: Color(red: 0, green: 0, blue: 0, opacity: 0.30), radius: 2.50, y: 0.50
                )
              }
              .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
            HStack(alignment: .top, spacing: 17) {
              Text("Auto-Launch:")
                .font(Font.custom("SF Pro", size: 13).weight(.bold))
                .lineSpacing(16)
                .foregroundColor(Color(red: 1, green: 1, blue: 1).opacity(0.85))
              HStack(spacing: 6) {
                ZStack() {
                  Text("􀆅")
                    .font(Font.custom("SF Pro", size: 9).weight(.bold))
                    .foregroundColor(.white)
                    .offset(x: 0, y: 0)
                }
                .frame(width: 14, height: 14)
                .background(
                  LinearGradient(gradient: Gradient(colors: [.white, Color(red: 1, green: 1, blue: 1).opacity(0)]), startPoint: .top, endPoint: .bottom)
                )
                .cornerRadius(3.50)
                .shadow(
                  color: Color(red: 0, green: 0.48, blue: 1, opacity: 0.12), radius: 0
                )
                Text("Open Gravity at Login")
                      .font(Font.custom("SF Pro", size: 13).weight(.regular))
                  .lineSpacing(16)
                  .foregroundColor(Color(red: 1, green: 1, blue: 1).opacity(0.85))
              }
            }
            .frame(maxWidth: .infinity)
            HStack(spacing: 17) {
              Text("App Version:")
                .font(Font.custom("SF Pro", size: 13).weight(.bold))
                .lineSpacing(16)
                .foregroundColor(Color(red: 1, green: 1, blue: 1).opacity(0.85))
              ZStack() {
                HStack(spacing: 6) {
                  Text("0.10.1")
                    .font(Font.custom("SF Pro", size: 13).weight(Font.Weight.regular))
                    .lineSpacing(16)
                    .foregroundColor(Color(red: 1, green: 1, blue: 1).opacity(0.85))
                }
                .offset(x: -70, y: 0)
                VStack(spacing: 0) {
                  Text("Check for Updates")
                    .font(Font.custom("SF Pro", size: 13))
                    .lineSpacing(1)
                    .foregroundColor(Color(red: 1, green: 1, blue: 1).opacity(0.85))
                }
                .padding(EdgeInsets(top: 3, leading: 7, bottom: 3, trailing: 7))
                .frame(width: 123)
                .background(Color(red: 1, green: 1, blue: 1).opacity(0.25))
                .cornerRadius(5)
                .offset(x: 22.50, y: 0)
              }
              .frame(width: 176, height: 20)
            }
            .frame(maxWidth: .infinity)
          }
          .frame(maxWidth: .infinity, minHeight: 143, maxHeight: 143)
        }
        .frame(width: 650, height: 316)
        .background(Color(red: 0.17, green: 0.17, blue: 0.17).opacity(0.80))
        .cornerRadius(10)
        .shadow(
          color: Color(red: 0, green: 0, blue: 0, opacity: 0.50), radius: 50, y: 20
        )    }
}

#Preview {
    GeneralSettingsView()
}
