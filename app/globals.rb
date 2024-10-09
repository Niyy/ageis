$uid_file ||= 0


def get_uid()
    out = $uid_file
    $uid_file += 1

    return out
end