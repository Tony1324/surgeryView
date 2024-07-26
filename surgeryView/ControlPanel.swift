//
//  ControlPanel.swift
//  surgeryView
//
//  Created by Tony Zhang on 3/24/24.
//

import SwiftUI
import RealityKit

struct ControlPanel: View {
    @Environment(ModelData.self) var modelData: ModelData
    var body: some View {
        NavigationStack{
            
            
            List{
                Section{
                    VStack(alignment: .leading, content: {
                        Text("Local Ip Address:")
                            .opacity(0.8)
                            .fontWeight(.bold)
                        Text("\(getLocalIPAddress() ?? "None found")")
                            .font(.system(size: 30, design: .monospaced))
                        Text("Port:")
                            .opacity(0.8)
                            .fontWeight(.bold)
                        Text("\(modelData.igtlClient?.port.debugDescription ?? "Default: 18944")")
                            .font(.system(size: 30, design: .monospaced))
                    })
                }
                NavigationLink {
                    List{
                        Button {
                            Task{
                                modelData.clearAll()
                                await modelData.loadSampleModels()
                            }
                        } label: {
                            Text("Load Sample Scene")
                        }
                        
                        Button {
                            Task{
                                modelData.clearAll()
                                modelData.startServer()
                            }
                        } label: {
                            Text("OpenIGTLink Connection")
                        }
//                        Button {
//                            Task{
//                                modelData.clearAll()
//                                modelData.stressTestCubeGrid()
//                            }
//                        } label: {
//                            Text("Performance Test")
//                        }
                        
                    }
                    .navigationTitle("Scenes")
                } label: {
                    Text("Scenes")
                }
                NavigationLink {
                    //TODO: update to multiselect
                        List{
                            Section {
                                Button {
                                    Task{
                                        modelData.clearAll()
                                    }
                                } label: {
                                    Text("Clear all models")
                                }
                            }
                            ForEach(modelData.models){ entity in
                                Button{
                                    if(modelData.selectedEntity == entity) {
                                        modelData.selectedEntity = nil
                                    } else {
                                        modelData.selectedEntity = entity
                                    }
                                }label:{
                                    Text(entity.name.isEmpty ? "Unnamed Object" : entity.name)
                                }
                                
                            }
                        }
                        .navigationTitle("Models")

                } label: {
                    Text("Models")
                }
                
            }
            
            .listStyle(.sidebar)
            .navigationTitle("Controls")
        }
    }
    
    func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                
                guard let interface = ptr?.pointee else { return "" }
                let addrFamily = interface.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                    
                    let name: String = String(cString: (interface.ifa_name))
                    if  name == "en0" || name == "en2" || name == "en3" || name == "en4" || name == "pdp_ip0" || name == "pdp_ip1" || name == "pdp_ip2" || name == "pdp_ip3" {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        
                        getnameinfo(interface.ifa_addr, socklen_t((interface.ifa_addr.pointee.sa_len)), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                        guard interface.ifa_addr.pointee.sa_family == 2 else {continue}
                        address = String(cString: hostname)
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return address ?? ""
    }
}

#Preview {
    ControlPanel()
        .environment(ModelData(models: [ModelEntity(mesh: .generateBox(size: 0.2),materials: [SimpleMaterial(color: .blue, isMetallic: false)])]))
}
