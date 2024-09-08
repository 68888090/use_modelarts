 export interface  MessageVO {
  role: MessageRoleEnum
  message: string
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
      message: '我最近在工作中遇到了一些PCB板的识别缺陷，请帮我分析一下可能的问题。'
    },
    {
      role: MessageRoleEnum.Other,
      message: '针对PCB板的人工智能识别，常见的缺陷可能包括：\n\n1. **识别精度低**：可能是因为训练数据不足或数据标注不准确。\n2. **识别速度慢**：可能是因为模型复杂度过高或计算资源不足。\n3. **错误分类**：可能是因为模型对某些类别的特征学习不充分。\n\n**修复建议**：\n\n1. **增加训练数据**：收集更多高质量的标注数据，并确保数据的多样性和代表性。\n2. **优化模型**：调整模型的架构或参数，尝试更适合的模型算法。\n3. **提升计算资源**：使用更强大的计算设备或优化现有资源配置。'
    }
  ]
}