import 'package:flutter/material.dart';

class CityDropdown extends StatelessWidget {
  final String? selectedCity;
  final List<String> cities;
  final Function(String) onCityChanged;

  const CityDropdown({
    super.key,
    required this.selectedCity,
    required this.cities,
    required this.onCityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedCity?.isEmpty ?? true ? null : selectedCity,
      decoration: InputDecoration(
        labelText: "City",
        hintText: "Select your city",
        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        contentPadding:
        const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.green),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.green, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      dropdownColor: Colors.white,
      icon: const Icon(Icons.arrow_drop_down, color: Colors.green),
      items: cities.map((city) {
        return DropdownMenuItem(
          value: city,
          child: Text(
            city,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          onCityChanged(value);
        }
      },
      validator: (value) => value == null ? 'Please select a city' : null,
    );
  }
}
