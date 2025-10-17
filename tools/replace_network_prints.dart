import 'dart:io';

/// 批量替换网络客户端中print语句的工具脚本
void main() async {
  final file = File('lib/src/core/network/fund_api_client.dart');

  if (!await file.exists()) {
    print('文件不存在: ${file.path}');
    return;
  }

  String content = await file.readAsString();

  // 替换规则映射
  final replacements = {
    "print('🌐 Fund API请求: \${options.method} \${options.path}')":
        "AppLogger.network(options.method, 'http://154.44.25.92:8080\${options.path}')",
    "print('✅ Fund API响应: \${response.statusCode} \${response.requestOptions.path}')":
        "AppLogger.network('RESPONSE', '\${response.requestOptions.path}', statusCode: response.statusCode)",
    "print('📄 Content-Type响应头: \$contentType')":
        "AppLogger.debug('Content-Type响应头', 'API', contentType)",
    "print('🔤 服务器指定的编码: \$contentType')":
        "AppLogger.debug('服务器编码', 'API', contentType)",
    "print('⚠️ 服务器未指定编码，可能使用默认编码')": "AppLogger.warn('服务器未指定编码，可能使用默认编码')",
    "print('⚠️ 服务器未返回Content-Type响应头')":
        "AppLogger.warn('服务器未返回Content-Type响应头')",
    "print('❌ Fund API错误: \${error.message} | \${error.requestOptions.path}')":
        "AppLogger.network('ERROR', '\${error.requestOptions.path}', responseData: error.message)",
    "print('📨 错误响应: \${error.response?.statusCode} \${error.response?.data}')":
        "AppLogger.error('API错误响应', '\${error.response?.statusCode}', null, 'Data: \${error.response?.data}')",
    "print('🔤 FundList原始响应数据长度: \${responseData.length}字符')":
        "AppLogger.debug('FundList响应数据', 'API', '\${responseData.length}字符')",
    "print('✅ FundList UTF-8解码成功，数据条数: \${decodedData.length}')":
        "AppLogger.business('FundList数据解析成功', 'API', '\${decodedData.length}条')",
    "print('🔤 原始响应数据长度: \${responseData.length}字符')":
        "AppLogger.debug('响应数据长度', 'API', '\${responseData.length}字符')",
    "print('✅ UTF-8解码成功，数据条数: \${decodedData.length}')":
        "AppLogger.business('数据解码成功', 'API', '\${decodedData.length}条')",
    "print('⚠️ 服务器返回500错误，返回空数据')": "AppLogger.warn('服务器返回500错误，返回空数据')",
    "print('❌ Fund API Dio错误: \${e.message}')":
        "AppLogger.error('Fund API Dio错误', e)",
    "print('📄 处理500错误，返回空数据')": "AppLogger.warn('处理500错误，返回空数据')",
    "print('🔤 FundDaily原始响应数据长度: \${responseData.length}字符')":
        "AppLogger.debug('FundDaily响应数据', 'API', '\${responseData.length}字符')",
    "print('✅ FundDaily UTF-8解码成功，数据条数: \${decodedData.length}')":
        "AppLogger.business('FundDaily数据解析成功', 'API', '\${decodedData.length}条')",
    "print('🔤 EtfSpot原始响应数据长度: \${responseData.length}字符')":
        "AppLogger.debug('EtfSpot响应数据', 'API', '\${responseData.length}字符')",
    "print('✅ EtfSpot UTF-8解码成功，数据条数: \${decodedData.length}')":
        "AppLogger.business('EtfSpot数据解析成功', 'API', '\${decodedData.length}条')",
    "print('🔤 FundPurchase原始响应数据长度: \${responseData.length}字符')":
        "AppLogger.debug('FundPurchase响应数据', 'API', '\${responseData.length}字符')",
    "print('✅ FundPurchase UTF-8解码成功，数据条数: \${decodedData.length}')":
        "AppLogger.business('FundPurchase数据解析成功', 'API', '\${decodedData.length}条')",
    "print('🔤 FundManagers原始响应数据长度: \${responseData.length}字符')":
        "AppLogger.debug('FundManagers响应数据', 'API', '\${responseData.length}字符')",
    "print('✅ FundManagers UTF-8解码成功，数据条数: \${decodedData.length}')":
        "AppLogger.business('FundManagers数据解析成功', 'API', '\${decodedData.length}条')",
  };

  // 应用替换
  for (final entry in replacements.entries) {
    content = content.replaceAll(entry.key, entry.value);
  }

  // 写回文件
  await file.writeAsString(content);
  print('网络客户端print语句替换完成: ${file.path}');
}
