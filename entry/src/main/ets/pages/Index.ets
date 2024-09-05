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
import { media } from '@kit.MediaKit';

interface FailResponse{
  erno:string,
  msg:string,
  words_result:string|null
}

let responseStr: string = ""
let originalData : DetectionResponse | FailResponse | null = null
let responseData: DetectionResponse |  null = null
let photoUri: string = ""
// 获取图片的原始宽高
let imgWidth = 500;
let imgHeight = 500;
let status:string = "fail"
let displayer =  display.getDefaultDisplaySync()

@Entry
@Component
struct Index {
  @State message: string = '点此选择照片';
  @State pixelMap: image.PixelMap | undefined = undefined
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
  private context2: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
  private offCanvas: OffscreenCanvas = new OffscreenCanvas(375, 600)
  private img: ImageBitmap | null = null
  private permissions: Array<Permissions> = ['ohos.permission.WRITE_IMAGEVIDEO', 'ohos.permission.READ_IMAGEVIDEO'];
  @State scaleValue: number = 1
  @State pinchValue: number = 1
  @State pinchX: number = 0
  @State pinchY: number = 0
  @State canvasVisible: Visibility = Visibility.Visible;
  @State gifVisible: Visibility = Visibility.None;

  build() {
    Column() {
      Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center }) {
        Canvas(this.context)
          .width('100%')
          .height('100%')
          .backgroundColor('#ffffff')
          .scale({ x: this.scaleValue, y: this.scaleValue, z: 1 })
          .onReady(() => {
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
      .visibility(this.canvasVisible)
      .height('55%')
      .margin({
        top: 100,
        bottom: 10,
        left: 5,
        right: 5
      });

      Image($r('app.media.1'))
        .height('55%')
        .visibility(this.gifVisible)
        .margin({
          top: 100,
          bottom: 10,
          left: 5,
          right: 5
        });

      Button(this.message, { type: ButtonType.Capsule })
        .fontSize(20)
        .onClick(() => {
          if (this.context) {
            this.context.clearRect(0, 0, this.context.width, this.context.height);
          }
          this.uploadAndDrawImage();
        });

      Canvas(this.context2)
        .width('100%')
        .height('20%')
        .margin({ top: 30, bottom: 10 })
        .backgroundColor("#d3d3d3")
        .onReady(() => {
          this.drawHints();
        })
        .width("90%")

    }.width('100%')
  }

  //绘制彩色指示图
  private drawHints() {
    const names: Array<string> = ["Mouse_bite", "Open_circuit", "Short", "Spur", "Spurious_copper"]
    this.context2.lineWidth = 2;
    this.context2.font = '48px Arial';
    this.context2.fillStyle = 'black';
    this.context2.fillText("颜色缺陷对应表：（图中括号内为预测置信度）", 20, 20);

    this.context2.font = '64px Arial';
    this.context2.strokeStyle = 'red';
    this.context2.beginPath();
    this.context2.rect(20, 40, 20, 10);
    this.context2.stroke();
    this.context2.fillStyle = 'red';
    this.context2.fillText(names[0], 60, 50);

    this.context2.strokeStyle = 'green';
    this.context2.beginPath();
    this.context2.rect(200, 40, 20, 10);
    this.context2.stroke();
    this.context2.fillStyle = 'green';
    this.context2.fillText(names[0], 240, 50);

    this.context2.strokeStyle = '#ffff00';
    this.context2.beginPath();
    this.context2.rect(20, 80, 20, 10);
    this.context2.stroke();
    this.context2.fillStyle = '#ffff00';
    this.context2.fillText(names[0], 60, 90);

    this.context2.strokeStyle = 'black';
    this.context2.beginPath();
    this.context2.rect(200, 80, 20, 10);
    this.context2.stroke();
    this.context2.fillStyle = 'black';
    this.context2.fillText(names[0], 240, 90);

    this.context2.strokeStyle = 'blue';
    this.context2.beginPath();
    this.context2.rect(20, 120, 20, 10);
    this.context2.stroke();
    this.context2.fillStyle = 'blue';
    this.context2.fillText(names[0], 60, 130);
  }

  // 延迟触发绘图
  async uploadAndDrawImage() {

    await this.example02();
    if(status=="success"){
      if (photoUri) { // 假设 photoUri 是图片的 URI
        this.img = new ImageBitmap(photoUri)
        this.gifVisible = Visibility.None
        this.canvasVisible = Visibility.Visible
        if (await this.drawImage()) {
          if (responseData) { // 绘制标注
            this.drawAnnotations(responseData, imgWidth, 370);
          }else {
            promptAction.showToast({
              message: '没有可用的DetectResponse类型数据'
            })
          }
        }
      } else {
        console.error('不存在有效的图片地址')
      }
    }else{
      this.gifVisible = Visibility.None
      this.canvasVisible = Visibility.Visible
      console.error("数据状态不可用")
    }
  }

  //显示图片
  public async drawImage(): Promise<boolean> {
    if (this.img) {
      let offContext = this.offCanvas.getContext("2d", this.settings);
      offContext.clearRect(0, 0, 375, 600)

      // 计算自适应的宽高
      let drawWidth = 375;
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
    // this.context.strokeStyle = 'green';
    this.context.lineWidth = 1;
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

      if (response.detection_classes[index] == "Mouse_bite") {
        this.context.strokeStyle = 'red';
        this.context.fillStyle = 'red';
      } else if (response.detection_classes[index] == "Open_circuit") {
        this.context.strokeStyle = 'green';
        this.context.fillStyle = 'green';
      } else if (response.detection_classes[index] == "Short") {
        this.context.strokeStyle = '#ffff00';
        this.context.fillStyle = '#ffff00';
      } else if (response.detection_classes[index] == "Spur") {
        this.context.strokeStyle = 'black';
        this.context.fillStyle = 'black';
      } else if (response.detection_classes[index] == "Spurious_copper") {
        this.context.strokeStyle = 'blue';
        this.context.fillStyle = 'blue';
      }
      // 绘制矩形框
      this.context.beginPath();
      this.context.rect(rectX, rectY, rectWidth, rectHeight);
      this.context.stroke();

      // this.context.fillStyle = 'white';
      this.context.font = '40px Arial';
      this.context.shadowColor = 'black';


      this.context.fillText("(" + (response.detection_scores[index] * 100).toFixed(0) + "%)",
        x21 + 5, y21 + 2);
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

  async example02(): Promise<void> {
    //打开相册选择器并设置图片选择特性
    let photoViewPicker = new picker.PhotoViewPicker();
    let photoSelectOption = new picker.PhotoSelectOptions();
    photoSelectOption.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;

    try {
      let photoSelectResult = await photoViewPicker.select(photoSelectOption);

      this.canvasVisible = Visibility.None
      this.gifVisible = Visibility.Visible

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
      //将PostAI返回的字符串数据赋值给当前文件中的全局变量responseStr
      // responseStr = responseArray
      // responseStr =
      //   "{\"detection_classes\": [\"Mouse_bite\", \"Mouse_bite\", \"Mouse_bite\", \"Open_circuit\", \"Mouse_bite\", \"Open_circuit\", \"Mouse_bite\", \"Open_circuit\", \"Mouse_bite\", \"Open_circuit\"], \"detection_boxes\": [[578, 646, 604, 672], [559, 609, 584, 640], [407, 264, 424, 303], [1052, 912, 1075, 925], [26, 740, 38, 761], [715, 1351, 743, 1358], [62, 1382, 84, 1397], [714, 1050, 724, 1074], [68, 864, 78, 884], [823, 1099, 834, 1108]], \"detection_scores\": [0.954258, 0.93341, 0.933286, 0.930765, 0.919465, 0.918447, 0.917989, 0.913556, 0.910603, 0.886787]}"
      responseStr = "{ \"detection_classes\": [], \"detection_boxes\": [],\"detection_scores\": []}"

      //解析服务器返回的数据为DetectionResponse
        try {
          originalData = JSON.parse(responseStr) as DetectionResponse;
          if(originalData){
            //可以解析但是不是有效数据
            if(originalData.detection_classes.length==0 && originalData.detection_boxes.length==0
              && originalData.detection_scores.length==0){
              promptAction.showToast({
                message: '当前上传图片不是有效芯片图片！',
                duration:3000
              })
              console.error("可以解析但是不是有效数据")
              //可以解析并且是有效数据
            }else if(originalData.detection_classes.length!=0 && originalData.detection_boxes.length!=0
              && originalData.detection_scores.length!=0){
              responseData = originalData
              status = "success"
            }
            //无法解析为有效对象
          }else{
            //尝试解析为FailResponse
            try {
              originalData = JSON.parse(responseStr) as FailResponse;
              promptAction.showToast({
                message: originalData.msg+",算法无法识别当前上传的图片",
                duration:3000
              })
              console.error(originalData.msg)
            } catch (error) {
              console.error("解析服务器返回数据为FailResponse类型时出错:", error);
            }
          }

        } catch (error) {
          console.error("服务器返回数据解析出错:", error);
        }

    }catch (err){
      if ((err as BusinessError).code !== undefined && (err as BusinessError).message !== undefined) {
        console.error(`操作失败: code: ${(err as BusinessError).code}, message: ${(err as BusinessError).message}`);
      } else {
        console.error("上传或解析过程中出错:", err);
      }
    }
  }
}