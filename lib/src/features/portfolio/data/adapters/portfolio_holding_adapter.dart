import 'package:hive/hive.dart';
import '../../domain/entities/portfolio_holding.dart';

/// PortfolioHolding Hive适配器
class PortfolioHoldingAdapter extends TypeAdapter<PortfolioHolding> {
  @override
  final int typeId = 0;

  @override
  PortfolioHolding read(BinaryReader reader) {
    return PortfolioHolding(
      fundCode: reader.readString(),
      fundName: reader.readString(),
      fundType: reader.readString(),
      holdingAmount: reader.readDouble(),
      costNav: reader.readDouble(),
      costValue: reader.readDouble(),
      marketValue: reader.readDouble(),
      currentNav: reader.readDouble(),
      accumulatedNav: reader.readDouble(),
      holdingStartDate: reader.read() as DateTime,
      lastUpdatedDate: reader.read() as DateTime,
      dividendReinvestment: reader.readBool(),
      status: HoldingStatus.values[reader.readByte()],
      notes: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, PortfolioHolding obj) {
    writer.writeString(obj.fundCode);
    writer.writeString(obj.fundName);
    writer.writeString(obj.fundType);
    writer.writeDouble(obj.holdingAmount);
    writer.writeDouble(obj.costNav);
    writer.writeDouble(obj.costValue);
    writer.writeDouble(obj.marketValue);
    writer.writeDouble(obj.currentNav);
    writer.writeDouble(obj.accumulatedNav);
    writer.write(obj.holdingStartDate);
    writer.write(obj.lastUpdatedDate);
    writer.writeBool(obj.dividendReinvestment);
    writer.writeByte(obj.status.index);
    writer.writeString(obj.notes ?? '');
  }
}
