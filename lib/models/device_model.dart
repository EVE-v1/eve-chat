class DeviceModel {
  final String id;
  final String name;
  final int rssi;
  final bool isConnected;

  DeviceModel({
    required this.id,
    required this.name,
    required this.rssi,
    this.isConnected = false,
  });

  DeviceModel copyWith({
    String? id,
    String? name,
    int? rssi,
    bool? isConnected,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}
