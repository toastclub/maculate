//
//  dict.hpp
//  maculate
//
//  Created by Evan Boehs on 1/22/25.
//

#ifndef DICT_H
#define DICT_H
#include <string>
using std::string;

enum DictType
{
    DICT_TYPE_FUNCTION,
    DICT_TYPE_UNIT,
};

struct DictItem
{
    string key;
    string value;
    string categories;
    DictType type;
};

typedef std::vector<DictItem> DictItems;

DictItems getDictItems(DictType type);

std::string getBodyForItem(const DictItem &item);
std::string getBodyForItem(const std::string &key, DictType type);

#endif // DICT_H
