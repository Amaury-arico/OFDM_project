function [signal_end] = channel_conv(signal,channel)

    signal_end = conv(channel,signal,'full');

end