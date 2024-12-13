import 'package:flutter/material.dart';

class RoleDropdown extends StatelessWidget {
  final String? selectedRole;
  final Function(String?) onRoleChanged;

  const RoleDropdown({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: selectedRole,
      hint: Text('Select Role'),
      onChanged: onRoleChanged,
      items: <String>['Owner', 'Administrator', 'Rider']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}
