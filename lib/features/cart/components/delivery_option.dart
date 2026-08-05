import 'package:flutter/material.dart';

class DeliveryOption extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget title;
  final Widget subtitle;
  final Widget trailing;

  const DeliveryOption({
    super.key,
    required this.selected,
    required this.onTap,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected
                  ? const Color(0xFFE23725)
                  : const Color(0xFFD9C7B8),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultTextStyle.merge(
                    style: const TextStyle(fontWeight: FontWeight.w900),
                    child: title,
                  ),
                  DefaultTextStyle.merge(
                    style: const TextStyle(color: Color(0xFF9B7D69)),
                    child: subtitle,
                  ),
                ],
              ),
            ),
            DefaultTextStyle.merge(
              style: TextStyle(
                color: selected
                    ? const Color(0xFF2A1F17)
                    : const Color(0xFF1B9E54),
                fontWeight: FontWeight.w900,
              ),
              child: trailing,
            ),
          ],
        ),
      ),
    );
  }
}
