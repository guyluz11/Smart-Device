import 'package:smart_device_dart/features/smart_device/application/usecases/button_object_u/button_object_local_u.dart';
import 'package:smart_device_dart/features/smart_device/application/usecases/cloud_value_change_u/cloud_value_change_u.dart';
import 'package:smart_device_dart/features/smart_device/application/usecases/devices_pin_configuration_u/pin_information.dart';
import 'package:smart_device_dart/features/smart_device/application/usecases/smart_device_objects_u/abstracts_devices/smart_device_static_abstract.dart';
import 'package:smart_device_dart/features/smart_device/application/usecases/wish_classes_u/blinds_wish_u.dart';
import 'package:smart_device_dart/features/smart_device/domain/entities/core_e/enums_e.dart';
import 'package:smart_device_dart/features/smart_device/infrastructure/datasources/core_d/manage_physical_components/device_pin_manager.dart';
import 'package:smart_device_dart/features/smart_device/infrastructure/datasources/smart_server_d/protoc_as_dart/smart_connection.pbgrpc.dart';

/// Object to control blinds
class BlindsObject extends SmartDeviceStaticAbstract {
  /// Setting up pins for up down, buttons for up down but not at the same time.
  BlindsObject(
      uuid,
      smartInstanceName,
      onOffPinNumber,
      onOffButtonPinNumber,
      int blindsUpPin,
      int upButtonPinNumber,
      int blindsDownPin,
      int downButtonPinNumber)
      : super(uuid, smartInstanceName, onOffPinNumber,
            onOffButtonPinNumber: onOffButtonPinNumber) {
    buttonPinUp = DevicePinListManager().getGpioPin(upButtonPinNumber);
    buttonPinDown = DevicePinListManager().getGpioPin(downButtonPinNumber);

    this.blindsUpPin = DevicePinListManager().getGpioPin(blindsUpPin);
    this.blindsDownPin = DevicePinListManager().getGpioPin(blindsDownPin);
    listenToTwoButtonsPress(cloudValueChangeU);

    setDeviceType(DeviceType.Blinds);
  }

  PinInformation buttonPinUp, blindsUpPin, buttonPinDown, blindsDownPin;

  @override
  List<String> getNeededPinTypesList() =>
      <String>['gpio', 'gpio', 'gpio', 'gpio'];

  @override
  void setDeviceType(DeviceType deviceType) => super.setDeviceType(deviceType);

  @override
  DeviceType getDeviceType() => DeviceType.Blinds;

  @override
  Future<String> executeActionString(
      String wishString, DeviceStateGRPC deviceState) async {
    final DeviceActions deviceAction =
        convertWishStringToWishesObject(wishString);
    return executeDeviceAction(deviceAction, deviceState);
  }

  @override
  Future<String> executeDeviceAction(
      DeviceActions deviceAction, DeviceStateGRPC deviceState) async {
    return deviceActionInBlindsClass(deviceAction, deviceState);
  }

  ///  All the wishes that are legit to execute from the blinds class
  Future<String> deviceActionInBlindsClass(
      DeviceActions deviceAction, DeviceStateGRPC deviceState) async {
    String wishExecuteResult;

    if (deviceAction == null) return 'Your wish does not exist in blinds class';
    if (deviceAction == DeviceActions.MoveUP) {
      wishExecuteResult = await BlindsWishU.BlindsUp(this);
    }
    if (deviceAction == DeviceActions.MoveDon) {
      wishExecuteResult = await BlindsWishU.blindsDown(this);
    }
    if (deviceAction == DeviceActions.Stop) {
      wishExecuteResult = await BlindsWishU.blindsStop(this);
    }

    if (wishExecuteResult != null) {
      if (deviceState != DeviceStateGRPC.waitingInFirebase) {
        final String deviceActionString =
            EnumHelper.deviceActionToString(deviceAction);
        super.updateThisDeviceDocumentCloudValue('action', deviceActionString);
        super.updateThisDeviceDocumentCloudValue(
            'state', DeviceStateGRPC.ack.toString());
      }
      return wishExecuteResult;
    }

    return wishInStaticClass(deviceAction, deviceState);
  }

  /// Listening to two buttons press but will not do action for the two of them
  /// at the same time.
  void listenToTwoButtonsPress(CloudValueChangeU cloudValueChangeU) {
    if (buttonPinUp != null &&
        buttonPinDown != null &&
        blindsUpPin != null &&
        blindsDownPin != null) {
      ButtonObjectLocalU(cloudValueChangeU: cloudValueChangeU)
          .listenToTwoButtonPressedButtOnlyOneCanBePressedAtATime(
              this, buttonPinUp, blindsUpPin, buttonPinDown, blindsDownPin);
    } else {
      print('Cannot listen to blinds, one of the variables is null');
    }
  }
}
