//
//  ContentView.swift
//  pulserunpilot
//
//  Created by 장진성 on 4/8/25.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    @State private var age: String = ""
    @State private var restingHR: String = ""
    @State private var authorized = false
    @State private var calculatedValues: (recommendedHR: Int, zones: [String: String])? = nil
    
    // HealthKit 초기화
    private let healthStore = HKHealthStore()
    
    var body: some View {
        NavigationView {
            if calculatedValues == nil {
                Form {
                    Section(header: Text("건강 데이터")) {
                        if !authorized {
                            Button("건강앱 접근 허가 받기") {
                                requestHealthAuthorization()
                            }
                        } else {
                            Text("HealthKit 권한이 부여되었습니다.")
                            // 실제 앱에서는 HealthKit에서 가져온 데이터를 아래에 표시할 수 있습니다.
                        }
                        
                        TextField("나이 (년)", text: $age)
                        #if os(iOS)
                            .keyboardType(.numberPad)
                        #endif
                        TextField("안정시 심박수", text: $restingHR)
                        #if os(iOS)
                            .keyboardType(.numberPad)
                        #endif
                    }
                    
                    Button("확인") {
                        calculateZones()
                    }
                }
                .navigationTitle("펄스런")
            } else {
                // 계산 결과를 보여주는 페이지
                ResultView(recommendedHR: calculatedValues!.recommendedHR, zones: calculatedValues!.zones)
            }
        }
    }
    
    // HealthKit 권한 요청 함수
    func requestHealthAuthorization() {
        // 읽어올 데이터 종류 정의: 심박수와 생년월일(나이 계산에 활용 가능)
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate),
              let dobType = HKCharacteristicType.characteristicType(forIdentifier: .dateOfBirth) else {
            return
        }
        let typesToRead: Set = [heartRateType, dobType]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                self.authorized = success
                if success {
                    // 실제 환경에서는 HealthKit에서 데이터를 가져와 age, restingHR 값을 갱신합니다.
                    // 테스트를 위해 예시 데이터를 설정할 수 있습니다.
                    self.age = "30"           // 예: 30세
                    self.restingHR = "70"      // 예: 안정시 심박수 70bpm
                }
            }
        }
    }
    
    // 적정 심박수 및 구간 계산 함수
    func calculateZones() {
        guard let ageInt = Int(age), let restingHRInt = Int(restingHR) else { return }
        let maxHR = 220 - ageInt  // 최대 심박수 (간단 계산식)
        // 여기서는 예시로 (안정시 심박수 + 최대 심박수) / 2를 적정 심박수로 설정합니다.
        let recommendedHR = (maxHR + restingHRInt) / 2
        
        // 각 운동존(zone) 범위 설정 (예시로 퍼센티지로 계산)
        let zone1 = "\(restingHRInt) ~ \(Int(Double(maxHR)*0.6))"
        let zone2 = "\(Int(Double(maxHR)*0.6)) ~ \(Int(Double(maxHR)*0.7))"
        let zone3 = "\(Int(Double(maxHR)*0.7)) ~ \(Int(Double(maxHR)*0.8))"
        let zone4 = "\(Int(Double(maxHR)*0.8)) ~ \(Int(Double(maxHR)*0.9))"
        let zone5 = "\(Int(Double(maxHR)*0.9)) ~ \(maxHR)"
        
        let zones = [
            "Zone 1": zone1,
            "Zone 2": zone2,
            "Zone 3": zone3,
            "Zone 4": zone4,
            "Zone 5": zone5
        ]
        calculatedValues = (recommendedHR, zones)
    }
}

struct ResultView: View {
    let recommendedHR: Int
    let zones: [String: String]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("적정 심박수: \(recommendedHR) bpm")
                .font(.title2)
            
            List {
                ForEach(zones.sorted(by: { $0.key < $1.key }), id: \.key) { zone, range in
                    HStack {
                        Text(zone)
                        Spacer()
                        Text(range)
                    }
                }
            }
        }
        .navigationTitle("계산 결과")
    }
}
