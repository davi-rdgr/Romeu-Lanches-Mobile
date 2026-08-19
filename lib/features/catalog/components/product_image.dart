import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Foto do produto. `imagemUrl` e opcional no cadastro do admin, e a URL pode
/// estar quebrada — nos dois casos cai no asset local.
class ProductImage extends StatelessWidget {
  final String? imageUrl;
  final double borderRadius;

  /// Botao "+" sobreposto no canto. Sem ele, a imagem e so imagem.
  final VoidCallback? onAdd;

  const ProductImage({
    super.key,
    this.imageUrl,
    this.borderRadius = 14,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFF6E6D4),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: imageUrl == null
                ? _fallback()
                : CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (_, _) => const ColoredBox(
                      color: Color(0xFFF6E6D4),
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFB59A86),
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (_, _, _) => _fallback(),
                  ),
          ),
        ),
        if (onAdd != null)
          Positioned(
            width: 25,
            height: 25,
            right: 0,
            bottom: 0,
            child: IconButton.filled(
              onPressed: onAdd,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFE23725),
                padding: EdgeInsets.zero,
                minimumSize: const Size(25, 25),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.add, size: 15),
            ),
          ),
      ],
    );
  }

  Widget _fallback() => Image.asset(
    'assets/images/burguer.jpg',
    fit: BoxFit.cover,
    width: double.infinity,
    height: double.infinity,
  );
}
