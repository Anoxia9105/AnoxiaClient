import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../framework/domain/ChatMessage.dart';
import 'MessageRenderStrategy.dart';

class ImageMessageStrategy extends MessageRenderStrategy {
  @override
  Widget buildContent(BuildContext context, ChatMessage message,Color textColor) {
    final url =  '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        url,
        width: 200,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50),
      ),
    );
  }

}