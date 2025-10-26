import 'package:hive/hive.dart';
import '../../domain/entities/fund_corporate_action.dart';

/// FundCorporateAction Hive适配器
class FundCorporateActionAdapter extends TypeAdapter<FundCorporateAction> {
  @override
  final int typeId = 1;

  @override
  FundCorporateAction read(BinaryReader reader) {
    return FundCorporateAction(
      fundCode: reader.readString(),
      fundName: reader.readString(),
      actionType: CorporateActionType.values[reader.readByte()],
      announcementDate: reader.read() as DateTime,
      recordDate: reader.read() as DateTime,
      exDate: reader.read() as DateTime,
      paymentDate: reader.read() as DateTime,
      year: reader.readInt(),
      dividendPerUnit: reader.readDouble(),
      dividendAmount: reader.readDouble(),
      splitType: reader.readString(),
      splitRatio: reader.readDouble(),
      navBeforeAdjustment: reader.readDouble(),
      navAfterAdjustment: reader.readDouble(),
      adjustmentFactor: reader.readDouble(),
      status: CorporateActionStatus.values[reader.readByte()],
      notes: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, FundCorporateAction obj) {
    writer.writeString(obj.fundCode);
    writer.writeString(obj.fundName);
    writer.writeByte(obj.actionType.index);
    writer.write(obj.announcementDate);
    writer.write(obj.recordDate);
    writer.write(obj.exDate);
    writer.write(obj.paymentDate);
    writer.writeInt(obj.year);
    writer.writeDouble(obj.dividendPerUnit ?? 0.0);
    writer.writeDouble(obj.dividendAmount ?? 0.0);
    writer.writeString(obj.splitType ?? '');
    writer.writeDouble(obj.splitRatio ?? 0.0);
    writer.writeDouble(obj.navBeforeAdjustment ?? 0.0);
    writer.writeDouble(obj.navAfterAdjustment ?? 0.0);
    writer.writeDouble(obj.adjustmentFactor ?? 0.0);
    writer.writeByte(obj.status.index);
    writer.writeString(obj.notes ?? '');
  }
}
