// import { BusinessError } from '@ohos.base';
import { rcp } from '@kit.RemoteCommunicationKit';
import { picker } from '@kit.CoreFileKit';
import fs from '@ohos.file.fs';
import { http } from '@kit.NetworkKit';
import { Button, display, promptAction } from '@kit.ArkUI'
import { RequestAI, DetectionResponse } from '../Utils/requestAI'
import { BusinessError } from '@kit.BasicServicesKit';
import { Context, Permissions } from '@kit.AbilityKit';
import PermissionsUtil from '../Utils/PermissionsUtil';
import { image } from '@kit.ImageKit';
import { resourceManager } from '@kit.LocalizationKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { responseString } from '../Utils/requestAI'
import { GG } from '../Utils/Pri_data';
import { media } from '@kit.MediaKit';
import { MessageRoleEnum, MessageVO,MessageVOImpl,TextTest } from '../Utils/chatUtil';
import BaiduHttp from '../Utils/BaiduHttp'
import {ChatResponse} from '../Utils/BaiduHttp'
import { TestType } from '@ohos/hypium';
import RequestGPT from '../Utils/requsetGPT'
import { PermissionManager} from '../Utils/VoicePermission'
import SpeechRecognizerManager from '../Utils/SpeechRecognizerManager'
import router from '@ohos.router';
import pan from '@ohos.bluetooth.pan';
import { AudioUtils } from '../Utils/AudioUtils';

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
//传输状态标记 1：正在传输；0：当前没有传输
let isLoading:boolean = false
let displayer =  display.getDefaultDisplaySync()

interface Rect {
  x: number;
  y: number;
  width: number;
  height: number;
}

export class Rect0 implements Rect {
  x: number;
  y: number;
  width: number;
  height: number;

  constructor(x:number,y:number,width:number,height:number) {
    // this.x = Math.max(Math.min(x,375),0)
    // this.y = Math.max(Math.min(y,600),0)
    this.x = Math.min(x,375)
    this.y = Math.min(y,600)
    //变化范围在20-200
    this.width = Math.max(Math.min(width,200),10)
    this.height = Math.max(Math.min(height,200),10)
  }
}

@Entry
@Component
struct Index {
  private scroller: Scroller= new Scroller(); // 创建一个滚动控制器;
  @State message: string = '点此选择照片';
  @State pixelMap: image.PixelMap | undefined = undefined
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
  private context2: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
  private context0: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
  private offCanvas: OffscreenCanvas = new OffscreenCanvas(375, 600)
  private img: ImageBitmap | null = null
  private permissions: Array<Permissions> = ['ohos.permission.WRITE_IMAGEVIDEO', 'ohos.permission.READ_IMAGEVIDEO'];
  @State scaleValue: number = 1
  @State pinchValue: number = 1
  @State pinchX: number = 0
  @State pinchY: number = 0
  @State canvasVisible: Visibility = Visibility.Visible;
  @State gifVisible: Visibility = Visibility.None;
  //绑定聊天界面输入框
  @State submitMsg: string = ''
  @State textInputMsg: string = ''
  @State messageArray:MessageVOImpl[] = []
  //语音识别
  @State Voicetext: string = ""
  //手势标记信号
  @State buttonVisibility:Visibility = Visibility.Hidden
  @State isMarking:boolean = false
  //记录方框数组
  @State rectangles: Rect[] = [];
  //矩形标记框拖动
  @State offsetX: number[] = [];
  @State offsetY: number[] = [];
  @State positionX: number[] = [];
  @State positionY: number[] = [];
  private panOption: PanGestureOptions = new PanGestureOptions({ direction: PanDirection.All ,fingers:1})
  //拖动角点缩放标志位
  @State panAction:string = ''
  //矩形标记框缩放
  @State xScaleValue: number[] = []
  @State yScaleValue: number[] = []
  @State boxPinchValue: number[] = []
  @State boxPinchX: number[] = []
  @State boxPinchY: number[] = []
  @State initPinchX: number[] = []
  @State initPinchY: number[] = []
  @State isPressing:boolean = false

  build() {
    Tabs({ barPosition: BarPosition.End }) {

      //故障显示界面
      TabContent(){
        Column() {
          Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center }) {
            Stack(){
              Canvas(this.context)
                .width('100%')
                .height('100%')
                .backgroundColor('#ffffff')
                .scale({ x: this.scaleValue, y: this.scaleValue, z: 1 })
                  //点击画布提示长按开启绘图模式
                .onClick(()=>{
                  if(!this.isMarking){
                    promptAction.showToast({
                      message:"长按进入手绘模式",
                      duration:1000
                    })
                  }
                })
                  //长按画布开启绘图模式，显示关闭按钮
                .gesture(
                  LongPressGesture({ repeat: false })
                    // 长按动作一结束触发
                    .onActionEnd((event: GestureEvent) => {
                      this.isMarking = true;
                      this.buttonVisibility = Visibility.Visible;
                    })
                )
                  //单指滑动，捕获起始点坐标，绘制矩形
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

              /// 动态渲染矩形
              ForEach(this.rectangles, (rect:Rect,index:number) => {
                Rect()
                  .position({x:rect.x,y:rect.y})
                  .width(rect.width)
                  .height(rect.height)
                  .fillOpacity(0)
                  .stroke('#ffc47007')
                  .strokeWidth(3)
                  .onClick((event)=>{
                    let rec = this.rectangles[index];
                    console.error("当前大小："+rec.width+','+rec.height)
                    //当前处于最小状态，难以缩放
                    //点击即可原地放大
                    if(rec.width==10 && rect.height==10){
                      let rec0:Rect = new Rect0(
                        rec.x,rec.y, 100,100)
                      this.rectangles[index] = rec0
                    }
                  })
                  .translate({  x: this.offsetX[index], y: this.offsetY[index], z: 0 })
                  //拖动手势
                  .gesture(
                    PanGesture(this.panOption)
                      .onActionStart((event: GestureEvent) =>{
                        let threshold = 10;
                        let x0 = event.fingerList[0].localX;
                        let y0 = event.fingerList[0].localY;
                        //左上
                        if(Math.abs(x0)<=threshold && Math.abs(y0)<=threshold){
                          this.panAction = 'LT';//left and top
                        }
                        //右上
                        else if(Math.abs(x0-rect.width)<=threshold && Math.abs(y0)<=threshold){
                          this.panAction = 'RT';//right and top
                        }
                        //左下
                        else if(Math.abs(x0)<=threshold && Math.abs(y0-rect.height)<=threshold){
                          this.panAction = 'LB';//left and bottom
                        }
                        //右下
                        else if(Math.abs(x0-rect.width)<=threshold && Math.abs(y0-rect.height)<=threshold){
                          this.panAction = 'RB';//right and bottom
                        }
                        //内部
                        else if(x0>=threshold && x0<=rect.width-threshold
                          && y0>=threshold && y0<=rect.height-threshold){
                          this.panAction = 'IN';//ineer
                        }
                      })
                      .onActionUpdate((event: GestureEvent) => {
                        if (event && this.isMarking) {
                          console.error(this.panAction)
                          //拖动点在内部，整体拖动
                          if(this.panAction=='IN'){
                            //以组件左上角为坐标原点偏移
                            this.offsetX[index] = event.offsetX
                            this.offsetY[index] = event.offsetY
                          }
                          //拖动点在左上角
                          else if(this.panAction=='LT'){
                            let newWidth = rect.width-event.offsetX;
                            let newHeight = rect.height-event.offsetY;
                            let newX = rect.x+event.offsetX;
                            let newY = rect.y+event.offsetY;
                            //保证是在向左或向上移动，且尺寸在要求范围内
                            if(newX>=(rect.x+rect.width-10)){
                              newX = rect.x+rect.width-10
                            }
                            if(newY>=(rect.y+rect.height-10)){
                              newY=(rect.y+rect.height-10)
                            }
                            if(newWidth>=0 && newWidth<=200 && newHeight>=0 && newHeight<=200){
                              let rec:Rect = new Rect0(newX,newY, newWidth,newHeight)
                              console.error('当前未赋值的rec位置：'+rec.x+'，'+rec.y)
                              this.rectangles[index] = rec
                            }
                          }
                          //拖动点在右上角
                          else if(this.panAction=='RT'){
                            let newWidth = rect.width+event.offsetX;
                            let newHeight = rect.height-event.offsetY;
                            let newX = rect.x;
                            let newY = rect.y+event.offsetY;
                            //保证是在向右或向上移动，且尺寸在要求范围内
                            if(newX>=10 && newWidth<=10){
                              newWidth = 10
                            }
                            if(newY>=(rect.y+rect.height-10)){
                              newY=(rect.y+rect.height-10)
                            }
                            if(newWidth>=0 && newWidth<=200 && newHeight>=0 && newHeight<=200){
                              let rec:Rect = new Rect0(
                                newX,newY, newWidth,newHeight)
                              this.rectangles[index] = rec
                            }
                          }
                          //拖动点在左下角
                          else if(this.panAction=='LB'){
                            let newWidth = rect.width-event.offsetX;
                            let newHeight = rect.height+event.offsetY;
                            let newX = rect.x+event.offsetX;
                            let newY = rect.y;
                            //保证是在向左或向下移动
                            if(newX>=(rect.x+rect.width-10)){
                              newX = rect.x+rect.width-10
                            }
                            if(newWidth>=0 && newWidth<=200 && newHeight>=0 && newHeight<=200){
                              let rec:Rect = new Rect0(
                                newX,newY, newWidth,newHeight)
                              this.rectangles[index] = rec
                            }
                          }
                          //拖动点在右下角
                          else if(this.panAction=='RB') {
                            let newWidth = rect.width+event.offsetX;
                            let newHeight = rect.height+event.offsetY;
                            if(newWidth<=10){
                              newWidth = 10
                            }
                            if(newHeight<=10){
                              newHeight = 10
                            }
                             let rec:Rect = new Rect0(
                              rect.x,rect.y,
                              newWidth,newHeight)
                            this.rectangles[index] = rec
                          }
                        }
                      })
                      .onActionEnd((event: GestureEvent) => {
                        if(event && this.isMarking){
                          //拖动点在内部，整体拖动
                          if(this.panAction=='IN'){
                            this.rectangles[index].x += this.offsetX[index];
                            this.rectangles[index].y += this.offsetY[index];
                            this.offsetX[index] = 0;
                            this.offsetY[index] = 0;
                          }
                          console.error("拖动结束")
                        }
                      })
                  )
                    //缩放手势（2指捏合）
                  // .scale({x: this.boxScaleValue[index], y: this.boxScaleValue[index], z: 1})
                  // .gesture(
                  //   PinchGesture({ fingers: 2 ,distance:1})
                  //     .onActionStart((event: GestureEvent) => {
                  //       console.log('Pinch start')
                  //       //缩放中心是现在的矩形中心
                  //       this.initPinchX[index] = rect.x + rect.width/2;
                  //       this.initPinchY[index] = rect.y + rect.height/2;
                  //     })
                  //     .onActionUpdate((event: GestureEvent) => {
                  //       if (event) {
                  //         //缩放过程中保持缩放中心不变
                  //         this.boxScaleValue[index] = this.boxPinchValue[index] * event.scale
                  //         this.boxPinchX[index] = this.initPinchX[index];
                  //         this.boxPinchY[index] = this.initPinchY[index];
                  //       }
                  //     })
                  //     .onActionEnd((event: GestureEvent) => {
                  //       this.boxPinchValue[index] = this.boxScaleValue[index]
                  //       console.info('Pinch end')
                  //     })
                  // )
              });
            }
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

          Canvas(this.context2)
            .width('100%')
            .height('20%')
            .margin({ left:30,bottom: 30 })
              // .backgroundColor("#d3d3d3")
            .onReady(() => {
              this.drawHints();
            })
            .width("90%")
            .height('10%')

          Button(this.message, { type: ButtonType.Capsule })
            .fontSize(20)
            .onClick(() => {
              if (this.context) {
                this.context.clearRect(0, 0, this.context.width, this.context.height);
              }
              if(isLoading==false){
                status = "fail"
                this.uploadAndDrawImage();
              }else{
                promptAction.showToast({
                  message:"数据正在传输，请稍等",
                  duration:3000
                })
              }
            });

          Row({space:20}){
            // //打印拖动状态，用于调试
            // Text(this.panAction)
            //   .fontColor('red')

            Button('添加', { type: ButtonType.Capsule })
              .fontSize(20)
              .margin(10)
              .visibility(this.buttonVisibility)
              .onClick(()=>{
                  this.addRect();
                  console.error('添加成功:'+this.rectangles.length+','+this.positionX.toString()+','
                    +this.positionY.toString())
              })

            Button('退出', { type: ButtonType.Capsule })
              .fontSize(20)
              .margin(10)
              .visibility(this.buttonVisibility)
              .onClick(()=>{
                this.buttonVisibility = Visibility.Hidden
                this.isMarking = false
              })

            Button('清空', { type: ButtonType.Capsule })
              .fontSize(20)
              .margin(10)
              .visibility(this.buttonVisibility)
              .onClick((event: ClickEvent) => {
                this.rectangles = []
            })
          }
        }.width('100%')
      }
      .tabBar('首页')

      //AI聊天界面
      TabContent() {
        Row() {
          Column() {
            headerText("Hello AI")


            // Button("申请权限")
            //   .onClick(this.fn1)
            // Button("实时语音识别")
            //   .onClick(this.fn2)

            List({space: 15, scroller: this.scroller}) {
              ForEach(this.messageArray, (item: MessageVOImpl) => {
                if (item.role === MessageRoleEnum.Mine) {
                  chatLine_mine(item.message)
                } else {
                  chatLine_other(item.message)
                }
              })
            }
            .height('80%')
            .width('100%')
            .padding({left:15,right:15})


            Row()
              {
              Image($r('app.media.yuyin'))
                .width(36)
                .height(36)
                .fillColor(0x000000)
                .layoutWeight('0.5')
                .margin({right:5})
                .parallelGesture(GestureGroup(GestureMode.Exclusive,
                  LongPressGesture({ repeat: false })
                    // 由于repeat设置为true，长按动作存在时会连续触发，触发间隔为duration（默认值500ms）
                    .onAction((event: GestureEvent) => {
                      if (event) {
                        // if(!this.isPressing){
                          // this.isPressing = true
                          AudioUtils.start()
                        promptAction.showToast({
                          message: '录音开始!'//弹窗内容
                        })
                        // }

                      }
                    })
                      // 长按动作一结束触发
                    .onActionEnd(async (event: GestureEvent) => {
                      promptAction.showToast({
                        message: '录音结束！'//弹窗内容
                      })
                      AudioUtils.stop()
                      let VoiceText =' '
                       await AudioUtils.release().then(async (temp:string)=>{
                         VoiceText = temp
                         this.messageArray.push(new MessageVOImpl(MessageRoleEnum.Mine, VoiceText.toString())) // 立刻展示我方对话

                         this.messageArray.push(new MessageVOImpl(MessageRoleEnum.Other, TextTest.dynamic)) // 展示对方对话
                         this.scroller.scrollEdge(Edge.Bottom) // 消息发送后 将列表滚动到底端
                         // 发送http请求
                         await BaiduHttp.requestChat(this.submitMsg, (responseText: string) => {
                           this.messageArray.pop()
                           this.messageArray.push(new MessageVOImpl(MessageRoleEnum.Other, responseText)) // 展示对方对话
                           this.scroller.scrollEdge(Edge.Bottom)
                         })
                       })


                      // this.isPressing = false
                    }
                    )
                )
                )
                // .onClick(()=>{
                //     console.info(`Succeeded in clicking the 'Next' button.`)
                //     // 跳转到第二页
                //     router.pushUrl({ url: 'pages/index_test_voice' }).then(() => {
                //       console.info('Succeeded in jumping to the second page.')
                //     }).catch((err:Error) => {
                //       console.error(`Failed to jump to the second page,error message is ${err.message}`)
                //     })
                // })

                // .bindMenu([
                //   {
                //     value:'上传当前图片',
                //     action: () => {
                //       console.info('handle Menu1 select')
                //     }
                //   },
                //   {
                //     value:'语音输入',
                //     action: () => {
                //       console.info('handle Menu1 select')
                //     }
                //   }
                // ])

                TextInput({placeholder: '有问题尽管问我~', text: this.textInputMsg})
                  .height(50)
                  .layoutWeight('4')
                  .margin(5)
                  .enterKeyType(EnterKeyType.Send)
                  .onChange((text) => {
                    this.submitMsg = text
                    this.textInputMsg = text
                  })
                  .onSubmit(async () => {
                    this.textInputMsg = "" // 点击发送后 输入框置空
                    this.messageArray.push(new MessageVOImpl(MessageRoleEnum.Mine, this.submitMsg)) // 立刻展示我方对话
                    this.scroller.scrollEdge(Edge.Bottom) // 消息发送后 将列表滚动到底端
                    this.messageArray.push(new MessageVOImpl(MessageRoleEnum.Other, TextTest.dynamic)) // 展示对方对话
                    // 发送http请求
                    await BaiduHttp.requestChat(this.submitMsg, (responseText: string) => {
                      this.messageArray.pop()
                      this.messageArray.push(new MessageVOImpl(MessageRoleEnum.Other, responseText)) // 展示对方对话
                      this.scroller.scrollEdge(Edge.Bottom)
                    })
                  }
                  )

                Button("发送",{type:ButtonType.Capsule})
                  .fontSize('20')
                  .layoutWeight('1.5')
                  .onClick(async () => {
                    this.textInputMsg = '' // 点击发送后 输入框置空
                    this.messageArray.push(new MessageVOImpl(MessageRoleEnum.Mine, this.submitMsg)) // 立刻展示我方对话
                    this.scroller.scrollEdge(Edge.Bottom) // 消息发送后 将列表滚动到底端
                    // 发送http请求
                    this.messageArray.push(new MessageVOImpl(MessageRoleEnum.Other, TextTest.dynamic)) // 展示对方对话

                    BaiduHttp.requestChat(this.submitMsg, (responseText: string) => {
                      this.messageArray.pop()
                      this.messageArray.push(new MessageVOImpl(MessageRoleEnum.Other, responseText)) // 展示对方对话
                      this.scroller.scrollEdge(Edge.Bottom) // 消息显示后 将列表滚动到底端
                    })
                  })


            }

            .width('95%')
          }
          .width('100%')
        }
        .height('100%')
      }
      .tabBar('AI对话')
    }
    .scrollable(false)
  }

  addRect() {
    this.rectangles.push({
      x: 0, // 初始X位置
      y: 0, // 初始Y位置
      width: 50, // 初始宽度
      height: 50, // 初始高度
    });
    //初始化拖动矩阵
    this.positionX.push(0)
    this.positionY.push(0)
    this.offsetX.push(0)
    this.offsetY.push(0)
    //初始化捏合矩阵
    this.xScaleValue.push(1);
    this.yScaleValue.push(1);
    this.boxPinchValue.push(1);
    this.boxPinchX.push(0);
    this.boxPinchY.push(0);
  }

  updateRectPosition(index: number, deltaX: number, deltaY: number) {
    this.rectangles[index].x += deltaX;
    this.rectangles[index].y += deltaY;
  }

  updateRectSize(index: number, scaleX: number, scaleY: number) {
    this.rectangles[index].width += scaleX;
    this.rectangles[index].height += scaleY;
  }


  //绘制彩色指示图
  private drawHints() {
    const names: Array<string> = ["Mouse_bite", "Open_circuit", "Short", "Spur", "Spurious_copper","手动标记"]
    this.context2.lineWidth = 2;
    this.context2.font = '48px Arial';
    this.context2.fillStyle = 'black';
    this.context2.fillText("颜色缺陷对照表：（图中括号内为预测置信度）", 10, 20);

    this.context2.font = '40px Arial';
    this.context2.fillStyle = 'red';
    this.context2.fillRect(10, 40, 10, 5);
    this.context2.fillStyle = 'black';
    this.context2.fillText(names[0], 30, 47);

    this.context2.fillStyle = 'green';
    this.context2.fillRect(120, 40, 10, 5);
    this.context2.fillStyle = 'black';
    this.context2.fillText(names[1], 140, 47);

    this.context2.fillStyle = '#ffff00';
    this.context2.fillRect(240, 40, 10, 5);
    this.context2.fillStyle = 'black';
    this.context2.fillText(names[2], 260, 47);

    this.context2.fillStyle = 'black';
    this.context2.fillRect(10, 60, 10, 5);
    this.context2.fillStyle = 'black';
    this.context2.fillText(names[3], 30, 67);

    this.context2.fillStyle = 'blue';
    this.context2.fillRect(120, 60, 10, 5);
    this.context2.fillStyle = 'black';
    this.context2.fillText(names[4], 140, 67);

    this.context2.fillStyle = '#ffc47007';
    this.context2.fillRect(240, 60, 10, 5);
    this.context2.fillStyle = 'black';
    this.context2.fillText(names[5], 260, 67);
  }

  // 延迟触发绘图
  async uploadAndDrawImage() {
    await this.example02();

    if(status=="success"){
      if (photoUri) {
        this.img = new ImageBitmap(photoUri)
        //清除加载动画
        this.gifVisible = Visibility.None
        this.canvasVisible = Visibility.Visible
        console.log('');
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
      //清除加载动画
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
      let uri = photoSelectResult.photoUris[0];
      photoUri = uri
      // console.log("Selected URI:" + uri);

      //选择图片后，隐藏画布，显示加载动画
      this.canvasVisible = Visibility.None
      this.gifVisible = Visibility.Visible

      // 创建requestAI实例
      let requestAIInstance = new RequestAI(uri);
      //标记传输状态为1：正在传输
      isLoading = true
      // 上传并获取响应数据
      await requestAIInstance.PostAI().then((response: GG) => {
        responseStr = response.data
        imgWidth = response.width
        imgHeight = response.height

      }).catch((error: Error) => {
        console.error('Error communicating with AI')
      })
      //标记传输状态为0
      isLoading = false

      console.log("服务器返回的数据:", responseStr);
      //将PostAI返回的字符串数据赋值给当前文件中的全局变量responseStr
      // responseStr = responseArray
      // responseStr =
      //   "{\"detection_classes\": [\"Mouse_bite\", \"Mouse_bite\", \"Mouse_bite\", \"Open_circuit\", \"Mouse_bite\", \"Open_circuit\", \"Mouse_bite\", \"Open_circuit\", \"Mouse_bite\", \"Open_circuit\"], \"detection_boxes\": [[578, 646, 604, 672], [559, 609, 584, 640], [407, 264, 424, 303], [1052, 912, 1075, 925], [26, 740, 38, 761], [715, 1351, 743, 1358], [62, 1382, 84, 1397], [714, 1050, 724, 1074], [68, 864, 78, 884], [823, 1099, 834, 1108]], \"detection_scores\": [0.954258, 0.93341, 0.933286, 0.930765, 0.919465, 0.918447, 0.917989, 0.913556, 0.910603, 0.886787]}"

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
              let constString = originalData.detection_classes.toString()+'\n这些关于PCB的问题是由什么工序造成的'
              this.messageArray.push(new MessageVOImpl(MessageRoleEnum.Mine, '这些关于PCB的问题是由什么工序造成的')) // 立刻展示我方对话
              this.scroller.scrollEdge(Edge.Bottom) // 消息发送后 将列表滚动到底端
              this.messageArray.push(new MessageVOImpl(MessageRoleEnum.Other, TextTest.dynamic)) // 展示对方对话
              // 发送http请求
              BaiduHttp.requestChat(constString, (responseText: string) => {
                this.messageArray.pop()
                this.messageArray.push(new MessageVOImpl(MessageRoleEnum.Other, responseText)) // 展示对方对话
                this.scroller.scrollEdge(Edge.Bottom)
              })
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

@Builder function headerText(title: string) {
  Text(title)
    .minFontSize(20).maxFontSize(30).maxLines(1)
    .fontWeight(FontWeight.Bold)
    .height('10%')
}

@Builder function chatLine_other(msg:string) {
  Row({space: 5}) {
    if(msg==TextTest.dynamic){
        Text(){
          ImageSpan($r('app.media.4'))
            .width('400px')
            .height('80px')
            .verticalAlign(ImageSpanAlignment.BOTTOM)
            // .align(ImageSpanAlignment.CENTER)
        }.chatLine_text_style_others1()
    }else
    Text(msg).chatLine_text_style_others()
  }
  .alignItems(VerticalAlign.Top)
  .justifyContent(FlexAlign.Start)
  .alignSelf(ItemAlign.Start);          // 控制整个 Row 左对齐
}

@Builder function chatLine_mine(msg:string) {
  Row({space: 5}) {
    Text(msg).chatLine_text_style_mine()

  }
  .alignItems(VerticalAlign.Top)
  .justifyContent(FlexAlign.End)
  .width('100%')
  .alignSelf(ItemAlign.End); // 控制整个 Row 右对齐// 控制气泡右对齐
}

@Extend(Text) function chatLine_text_style_mine() {
  .fontSize(20)
  .fontColor(Color.White)
  .width('65%')
  .lineHeight(25)
  .backgroundColor('rgba(41, 83, 243, 1.00)')
  .padding(12)
  .border({radius: 10})
  .textAlign(TextAlign.Start)  // 确保文本内容左对齐
  .alignSelf(ItemAlign.Start)  // 确保整个 Text 元素左对齐
}
@Extend(Text) function chatLine_text_style_others() {
  .fontSize(20)
  .fontColor(Color.Black)
  .width('90%')
  .lineHeight(25)
  .backgroundColor('rgba(229, 228, 228, 1.00)')
  .padding(12)
  .border({radius: 10})
  .textAlign(TextAlign.Start)  // 确保文本内容左对齐
  .alignSelf(ItemAlign.Start)  // 确保整个 Text 元素左对齐
}

@Extend(Text) function chatLine_text_style_others1() {
  .fontSize(20)
  .fontColor(Color.Black)
  .width('40%')
  .lineHeight(25)
  .backgroundColor('rgba(229, 228, 228, 1.00)')
  .padding(12)
  .border({radius: 10})
  .textAlign(TextAlign.Start)  // 确保文本内容左对齐
  .alignSelf(ItemAlign.Start)  // 确保整个 Text 元素左对齐
}

