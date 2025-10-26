import 'package:hive/hive.dart';
import '../../domain/entities/fund_split_detail.dart';

/// 基金拆分详情Hive适配器
class FundSplitDetailAdapter extends TypeAdapter<FundSplitDetail> {
  @override
  final int typeId = 2;

  @override
  FundSplitDetail read(BinaryReader reader) {
    return FundSplitDetail(
      fundCode: reader.readString(),
      fundName: reader.readString(),
      year: reader.readInt(),
      splitDate: reader.read() as DateTime,
      splitType: reader.readString(),
      splitRatio: reader.readDouble(),
      navBeforeSplit: reader.readDouble(),
      navAfterSplit: reader.readDouble(),
      sharesBeforeSplit: reader.readDouble(),
      sharesAfterSplit: reader.readDouble(),
      recordDate: reader.read() as DateTime,
      executionDate: reader.read() as DateTime,
      splitReason: reader.read() as String?,
      status: SplitStatus.values[reader.readByte()],
      notes: reader.read() as String?,
    );
  }

  @override
  void write(BinaryWriter writer, FundSplitDetail obj) {
    writer.writeString(obj.fundCode);
    writer.writeString(obj.fundName);
    writer.writeInt(obj.year);
    writer.write(obj.splitDate);
    writer.writeString(obj.splitType);
    writer.writeDouble(obj.splitRatio);
    writer.writeDouble(obj.navBeforeSplit);
    writer.writeDouble(obj.navAfterSplit);
    writer.writeDouble(obj.sharesBeforeSplit);
    writer.writeDouble(obj.sharesAfterSplit);
    writer.write(obj.recordDate);
    writer.write(obj.executionDate);
    writer.writeString(obj.splitReason ?? '');
    writer.writeByte(obj.status.index);
    writer.writeString(obj.notes ?? '');
  }
}
