namespace Array {
    func push_one{calldata_len: felt, calldata: felt*}(data: felt) {
        assert calldata[calldata_len] = data;
        let calldata_len = calldata_len + 1;
        return ();
    }

    func push_many{calldata_len: felt, calldata: felt*}(data_len: felt, data: felt*) {
        if (data_len == 0) {
            return ();
        }
        push_one([data]);
        return push_many(data_len - 1, data + 1);
    }

    func push_class_init{calldata_len: felt, calldata: felt*}(
        class_hash: felt, init_data_len: felt, init_data: felt*
    ) {
        push_one(class_hash);
        push_one(init_data_len);
        return push_many(init_data_len, init_data);
    }
}
