import 'ros_client.dart';
import 'topics.dart';

/// Mapping sang rcl_interfaces/msg/Parameter.type.
/// https://docs.ros.org/en/humble/p/rcl_interfaces/msg/ParameterType.html
enum RosParamType {
  notSet(0, null),
  boolean(1, 'bool_value'),
  integer(2, 'integer_value'),
  double(3, 'double_value'),
  string(4, 'string_value'),
  byteArray(5, 'byte_array_value'),
  boolArray(6, 'bool_array_value'),
  integerArray(7, 'integer_array_value'),
  doubleArray(8, 'double_array_value'),
  stringArray(9, 'string_array_value');

  final int code;
  final String? field;
  const RosParamType(this.code, this.field);
}

class RosParamValue {
  final RosParamType type;
  final dynamic value;
  const RosParamValue(this.type, this.value);

  factory RosParamValue.fromBool(bool v) =>
      RosParamValue(RosParamType.boolean, v);
  factory RosParamValue.fromInt(int v) =>
      RosParamValue(RosParamType.integer, v);
  factory RosParamValue.fromDouble(double v) =>
      RosParamValue(RosParamType.double, v);
  factory RosParamValue.fromString(String v) =>
      RosParamValue(RosParamType.string, v);

  Map<String, dynamic> toJson() => {
        'type': type.code,
        if (type.field != null) type.field!: value,
      };
}

/// Wrap gọi /<node>/set_parameters và /<node>/get_parameters.
class RosParamService {
  RosParamService(this.client, this.node);
  final RosClient client;
  final String node;

  Future<bool> setParam(String name, RosParamValue value) async {
    final res = await client.callService(
      name: RosServices.setParameters(node),
      type: RosTypes.setParamsSrv,
      request: {
        'parameters': [
          {'name': name, 'value': value.toJson()},
        ],
      },
    );
    final list = (res?['results'] as List?) ?? const [];
    if (list.isEmpty) return false;
    return list.every((r) => (r as Map)['successful'] == true);
  }

  Future<Map<String, dynamic>?> getParams(List<String> names) async {
    return client.callService(
      name: RosServices.getParameters(node),
      type: RosTypes.getParamsSrv,
      request: {'names': names},
    );
  }
}
