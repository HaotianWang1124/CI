"""
Created on Wed Sep 27 14:46:11 2023

@author: Haotian Wang
"""

import pandas as pd
import numpy as np
import torch
import torch.nn as nn
from torch.utils.data import DataLoader, TensorDataset
from sklearn.model_selection import KFold

# 读取CSV文件
csv_file = r'D:\VIDA\LSTM\Dataset\TRN_SET_9_PRA.csv'  # 替换为你的CSV文件路径
data = pd.read_csv(csv_file)

# 提取训练目标和训练数据
target_column = 'SM'
feature_columns = ['Kin', 'Pres', 'RH', 'U', 'Ta', 'RG_SLM001', 'NDVI', 'LAI', 'ET']
time_column = 'DN'

# 提取训练目标列
target = data[target_column].values.astype(np.float32)

# 提取训练数据列
features = data[feature_columns].values.astype(np.float32)

# 数据预处理
min_value = np.min(features)
max_value = np.max(features)
features = (features - min_value) / (max_value - min_value)

# 定义时间窗口大小
window_size = 1  # 可根据需要调整

# 创建时间窗口数据
X, y = [], []
for i in range(len(target) - window_size):
    X.append(features[i:i + window_size])
    y.append(target[i + window_size])

X = np.array(X)
y = np.array(y)

# 转换为PyTorch张量
X_tensor = torch.tensor(X)
y_tensor = torch.tensor(y)

# 创建数据集和数据加载器
dataset = TensorDataset(X_tensor, y_tensor)

# 定义LSTM模型
class LSTMModel(nn.Module):
    def __init__(self, input_size, hidden_size, num_layers, output_size):
        super(LSTMModel, self).__init__()
        self.lstm = nn.LSTM(input_size, hidden_size, num_layers, batch_first=True)
        self.fc = nn.Linear(hidden_size, output_size)

    def forward(self, x):
        out, _ = self.lstm(x)
        out = self.fc(out[:, -1, :])
        return out

# 定义损失函数
criterion = nn.MSELoss()

# 定义参数范围
param_ranges = {
    'num_layers': [1, 2, 3],
    'hidden_size': [32, 64, 128, 256],
    'batch_size': [32, 64, 128, 256],
    'num_epochs': [50, 100, 150, 200, 250, 300, 350, 400, 450, 500]
}

# 存储所有参数设置的结果
results = []

for num_layers in param_ranges['num_layers']:
    for hidden_size in param_ranges['hidden_size']:
        for batch_size in param_ranges['batch_size']:
            for num_epochs in param_ranges['num_epochs']:
                # 添加十折交叉验证
                num_folds = 10
                kf = KFold(n_splits=num_folds)

                # 存储每个折的模型和性能指标
                fold_losses = []

                for fold, (train_idx, val_idx) in enumerate(kf.split(X)):
                    # 分割数据集为训练集和验证集
                    train_dataset = TensorDataset(X_tensor[train_idx], y_tensor[train_idx])
                    val_dataset = TensorDataset(X_tensor[val_idx], y_tensor[val_idx])

                    train_dataloader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True)
                    val_dataloader = DataLoader(val_dataset, batch_size=batch_size, shuffle=False)

                    # 初始化模型
                    model = LSTMModel(9, hidden_size, num_layers, 1)

                    # 初始化优化器
                    optimizer = torch.optim.Adam(model.parameters(), lr=0.001)

                    # 训练模型
                    for epoch in range(num_epochs):
                        for batch_X, batch_y in train_dataloader:
                            optimizer.zero_grad()
                            output = model(batch_X)
                            loss = criterion(output, batch_y.unsqueeze(1))
                            loss.backward()
                            optimizer.step()

                        if (epoch + 1) % 10 == 0:
                            print(f'Fold [{fold + 1}/{num_folds}], Epoch [{epoch + 1}/{num_epochs}], Loss: {loss.item():.4f}')

                    # 在验证集上计算损失
                    val_loss = 0.0
                    with torch.no_grad():
                        for batch_X, batch_y in val_dataloader:
                            output = model(batch_X)
                            val_loss += criterion(output, batch_y.unsqueeze(1)).item()
                    fold_losses.append(val_loss / len(val_dataloader))

                # 计算十折交叉验证的平均损失
                avg_loss = np.mean(fold_losses)

                # 记录参数设置和平均损失
                result = {
                    'num_layers': num_layers,
                    'hidden_size': hidden_size,
                    'batch_size': batch_size,
                    'num_epochs': num_epochs,
                    'avg_loss': avg_loss
                }

                results.append(result)

# 将结果转换为DataFrame
results_df = pd.DataFrame(results)

# 将结果保存到Excel文件
excel_file = r'D:\VIDA\LSTM\Dataset\Output\parameter_search_results.xlsx'  # 替换为你希望保存的文件名
results_df.to_excel(excel_file, index=False)


print("Losses and model parameters saved to Excel file:", excel_file)