# (generated with --quick)

import nri.types.definitions
from typing import SupportsInt, Type, TypeVar, Union

_CoreID: Type[nri.types.definitions._CoreID]
_Hz: Type[nri.types.definitions._Hz]
_MicroJoules: Type[nri.types.definitions._MicroJoules]
_MicroWatts: Type[nri.types.definitions._MicroWatts]
_PUID: Type[nri.types.definitions._PUID]
_PkgID: Type[nri.types.definitions._PkgID]
_Temperature: Type[nri.types.definitions._Temperature]
_Time: Type[nri.types.definitions._Time]

a = TypeVar('a')

def mkCoreID(s: Union[str, SupportsInt]) -> nri.types.definitions._CoreID: ...
def mkHz(s: Union[str, SupportsInt]) -> nri.types.definitions._Hz: ...
def mkMicroJoules(s: Union[str, SupportsInt]) -> nri.types.definitions._MicroJoules: ...
def mkMicroWatts(s: Union[str, SupportsInt]) -> nri.types.definitions._MicroWatts: ...
def mkPUID(s: Union[str, SupportsInt]) -> nri.types.definitions._PUID: ...
def mkPkgID(s: Union[str, SupportsInt]) -> nri.types.definitions._PkgID: ...
def mkTemperature(s: Union[str, SupportsInt]) -> nri.types.definitions._Temperature: ...
def mkTime(s: Union[str, SupportsInt]) -> nri.types.definitions._Time: ...