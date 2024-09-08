export interface MessageVO {
  role: MessageRoleEnum
  message: string
}
export class MessageVOImpl implements MessageVO {
  role: MessageRoleEnum
  message: string
  constructor(role: MessageRoleEnum,message: string) {
    this.role = role
    this.message = message
  }
}

export enum MessageRoleEnum {
  // 我方
  Mine,
  // 对方
  Other
}

export class TextTest {
  static readonly Text: MessageVO[] = [
    {
      role: MessageRoleEnum.Mine,
      message: '上图中出现的Mouse-bite类缺陷是什么工序造成的？'
    },
    {
      role: MessageRoleEnum.Other,
      message: '在PCB（印制电路板）制造过程中，Mouse-bite是一种常见的缺陷，通常表现为在PCB板边缘或钻孔周围出现的小缺口，类似老鼠咬过的痕迹。它们通常是由拼板分离工序中产生的。\n' +
        '\n' +
        '具体来说，Mouse-bite缺陷主要是由于以下原因造成的：\n' +
        '\n' +
        '1.拼板工序：在PCB制造中，多个电路板通常被组合在一起，通过连接桥（tab）相连。为了将这些拼板分开，通常使用打孔或打槽的方法，这些孔或槽称为“Mouse-bites”。当拼板被分离时，这些地方容易留下小缺口。\n' +
        '\n' +
        '2.分板工序：拼板分离时，可能使用机械切割或冲孔工具，如果分离过程不够精确或工艺设备不够稳定，就可能造成边缘的破损，形成Mouse-bite类缺陷。\n' +
        '\n' +
        '3.打孔工序：在钻孔过程中，如果钻头磨损严重或者工艺参数不当，也可能导致孔周围的材料剥落，出现类似Mouse-bite的缺陷。\n' +
        '\n' +
        '因此，Mouse-bite类缺陷主要与PCB板的拼板设计和分离工艺有关，通常在拼板分离的阶段更容易出现。'
    }
  ]
}