%% Write MNIST Images to text file
%{
    Writes the MNIST data set into text files. Each row represents a single
    MNIST image. Also Writes the trained weights to text files.
%}

addpath(genpath('./dlt_cnn_map_dropout_nobiasnn'));
load mnist_uint8;
train_x = double(train_x) / 255;
test_x  = double(test_x)  / 255;
train_y = double(train_y);
test_y  = double(test_y);

%writematrix(train_y,'train_labels.txt');
writematrix(test_y,'test_labels.txt');
%writematrix(train_x,'train_data.txt');
writematrix(test_x,'test_data.txt');

%writematrix(nn.W{1}, 'weights_layer1.txt');
%writematrix(nn.W{2}, 'weights_layer2.txt');
%writematrix(nn.W{3}, 'weights_layer3.txt');