// import { BusinessError } from '@ohos.base';
import { rcp } from '@kit.RemoteCommunicationKit';
import { picker } from '@kit.CoreFileKit';
import fs from '@ohos.file.fs';
import { http } from '@kit.NetworkKit';
import { Button, display, promptAction } from '@kit.ArkUI'
import { RequestAI, DetectionResponse } from '../Utils/requestAI'
import { BusinessError } from '@kit.BasicServicesKit';
import { Permissions } from '@kit.AbilityKit';
import PermissionsUtil from '../Utils/PermissionsUtil';
import { image } from '@kit.ImageKit';
import { resourceManager } from '@kit.LocalizationKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { responseString } from '../Utils/requestAI'
import { GG } from '../Utils/Pri_data';

let responseStr: string = ""
let responseData: DetectionResponse | null = null
let photoUri: string = ""
// 获取图片的原始宽高
let imgWidth = 500;
let imgHeight = 500;

async function example02(): Promise<void> {
  //打开相册选择器并设置图片选择特性
  let photoViewPicker = new picker.PhotoViewPicker();
  let photoSelectOption = new picker.PhotoSelectOptions();
  photoSelectOption.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;

  try {
    let photoSelectResult = await photoViewPicker.select(photoSelectOption);
    let uri = photoSelectResult.photoUris[0];
    photoUri = uri
    console.log("Selected URI:" + uri);
    // getImageSize(uri)
    // 创建requestAI实例
    let requestAIInstance = new RequestAI(uri);
    // 上传并获取响应数据
    await requestAIInstance.PostAI().then((response: GG) => {
      responseStr = response.data
      imgWidth = response.width
      imgHeight = response.height
    }).catch((error: Error) => {
      console.error('Error communicating with AI')
    })

    console.log("服务器返回的数据:", responseStr);

    //解析服务器返回的数据为DetectionResponse
    try {
      responseData = JSON.parse(responseStr) as DetectionResponse;
      console.error("解析后的数据:", responseData.detection_classes[0]);
    } catch (error) {
      console.error("解析服务器返回的数据时出错:", error);
    }

  } catch (err) {
    if ((err as BusinessError).code !== undefined && (err as BusinessError).message !== undefined) {
      console.error(`操作失败: code: ${(err as BusinessError).code}, message: ${(err as BusinessError).message}`);
    } else {
      console.error("上传或解析过程中出错:", err);
    }
  }
}

@Entry
@Component
struct Index {
  @State message: string = '点此选择照片';
  @State pixelMap: image.PixelMap | undefined = undefined
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
  private offCanvas: OffscreenCanvas = new OffscreenCanvas(400, 600)
  private img: ImageBitmap | null = null
  private permissions: Array<Permissions> = ['ohos.permission.WRITE_IMAGEVIDEO', 'ohos.permission.READ_IMAGEVIDEO'];
  @State scaleValue: number = 1
  @State pinchValue: number = 1
  @State pinchX: number = 0
  @State pinchY: number = 0

  build() {
    Column() {
      Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center }) {
        Canvas(this.context)
          .width('100%')
          .height('100%')
          .backgroundColor('#ffffff')
          .scale({ x: this.scaleValue, y: this.scaleValue, z: 1 })
          .onReady(() => {
            // this.drawImage();
          })
          .gesture(PinchGesture({ fingers: 2 })

            .onActionStart((event: GestureEvent) => {
              console.info('Pinch start')
            })
            .onActionUpdate((event: GestureEvent) => {
              if (event) {
                this.scaleValue = this.pinchValue * event.scale
                this.pinchX = event.pinchCenterX
                this.pinchY = event.pinchCenterY
              }
            })
            .onActionEnd((event: GestureEvent) => {
              this.pinchValue = this.scaleValue
              console.info('Pinch end')
            })
          )
      }
      .backgroundColor('red')
      .height('60%')
      .margin({
        top: 100,
        bottom: 10,
        left: 5,
        right: 5
      });

      Button(this.message, { type: ButtonType.Capsule })
        .fontSize(20)
        .margin({})
        .onClick(() => {
          if (this.context) {
            this.context.clearRect(0, 0, this.context.width, this.context.height);
          }
          this.uploadAndDrawImage();
        });
      Image(photoUri)
    }.width('100%')

  }

  // 延迟触发绘图
  async uploadAndDrawImage() {
    await example02();

    if (photoUri) { // 假设 photoUri 是图片的 URI

      this.img = new ImageBitmap(photoUri)

      if (await this.drawImage()) {
        if (responseData) { // 绘制标注
          this.drawAnnotations(responseData, imgWidth, 400);
        } else {
          promptAction.showToast({
            message: '没有可用的DetectResponse类型数据'
          })
        }
      }
    } else {
      console.error('不存在有效的图片地址')
    }
  }

  //显示图片
  private async drawImage(): Promise<boolean> {
    if (this.img) {
      let offContext = this.offCanvas.getContext("2d", this.settings);
      offContext.clearRect(0,0,400,600)

      // 计算自适应的宽高
      let drawWidth = 400;
      let drawHeight = (imgHeight / imgWidth) * drawWidth;

      // 使用drawImage接口将图片画在（0，0）为起点，宽400，高自适应的区域
      offContext.drawImage(this.img, 0, 0, drawWidth, drawHeight);
      // 将离屏绘制的内容画到canvas组件上
      let image = this.offCanvas.transferToImageBitmap();
      this.context.transferFromImageBitmap(image);
      return true
    } else {
      promptAction.showToast({
        message: '创建图片实例ImageBitmap未成功'
      })
      return false
    }
  }

  async aboutToAppear(): Promise<void> {
    PermissionsUtil.checkPermissions(this.permissions)
  }

  //标记信息
  private drawAnnotations(response: DetectionResponse,
    imgWidth: number, drawWidth: number) {

    // 设置检测框
    this.context.strokeStyle = 'green';
    this.context.lineWidth = 0.5;
    //计算缩放率
    let ratio = drawWidth / imgWidth

    response.detection_boxes.forEach((box: number[], index: number) => {

      let y1 = box[0];
      let x1 = box[1];
      let y2 = box[2];
      let x2 = box[3];

      // 计算实际坐标
      let rectX = x1 * ratio;
      let rectY = y1 * ratio;
      let rectWidth = (x2 - x1) * ratio;
      let rectHeight = (y2 - y1) * ratio;
      let x21 = x2 * ratio
      let y21 = y2 * ratio

      // 绘制矩形框
      this.context.beginPath();
      this.context.rect(rectX, rectY, rectWidth, rectHeight);
      this.context.stroke();

      // 绘制标注文本
      this.context.fillStyle = 'white';
      this.context.font = '24px Arial';
      this.context.fillText(response.detection_classes[index] + "(" +
      (response.detection_scores[index] * 100).toFixed(0) + "%)",
        rectX, y21 + 3);
    });
  }

  async packingPixelMap2Jpg(pixelMap: PixelMap): Promise<ArrayBuffer> {
    const imagePackerApi = image.createImagePacker();
    const packOpts: image.PackingOption = { format: "image/jpeg", quality: 98 };
    let imageBuffer: ArrayBuffer = new ArrayBuffer(1);
    try {
      // 图片压缩或重新打包
      imageBuffer = await imagePackerApi.packing(pixelMap, packOpts);
    } catch (err) {
      console.error(`Invoke packingPixelMap2Jpg failed, err: ${JSON.stringify(err)}`);
    }
    return imageBuffer;
  }

}

