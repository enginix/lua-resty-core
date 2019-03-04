-- Copyright (C) by Yichun Zhang (agentzh)
-- Copyright (C) by OpenResty Inc.

local ffi = require("ffi")
local base = require("resty.core.base")


local ffi_str = ffi.string
local type = type
local C = ffi.C
local NGX_ERROR = ngx.ERROR


local _M = { version = base.version }


ffi.cdef[[
typedef intptr_t        ngx_int_t;

void ngx_encode_base64url(ngx_str_t *dst, ngx_str_t *src);
ngx_int_t ngx_decode_base64url(ngx_str_t *dst, ngx_str_t *src);
]]


local get_string_buf = base.get_string_buf


local dst_str_t = ffi.new("ngx_str_t[1]")
local src_str_t = ffi.new("ngx_str_t[1]")


local function base64_encoded_length(len)
    return ((len + 2) / 3) * 4
end


local function base64_decoded_length(len)
    return ((len + 3) / 4) * 3
end


function _M.encode_base64url(s)
    if type(s) ~= "string" then
        return nil, "must provide a string"
    end

    local len = #s
    local trans_len = base64_encoded_length(len)

    src_str_t[0].data = s
    src_str_t[0].len = len

    dst_str_t[0].data = get_string_buf(trans_len)
    dst_str_t[0].len = trans_len

    C.ngx_encode_base64url(dst_str_t, src_str_t)

    return ffi_str(dst_str_t[0].data, dst_str_t[0].len)
end


function _M.decode_base64url(s)
    if type(s) ~= "string" then
        return nil, "must provide a string"
    end

    local len = #s
    local trans_len = base64_decoded_length(len)

    src_str_t[0].data = s
    src_str_t[0].len = len

    dst_str_t[0].data = get_string_buf(trans_len)
    dst_str_t[0].len = trans_len

    local ret = C.ngx_decode_base64url(dst_str_t, src_str_t)
    if ret == NGX_ERROR then
        return nil, "invalid input"
    end

    return ffi_str(dst_str_t[0].data, dst_str_t[0].len)
end


return _M
