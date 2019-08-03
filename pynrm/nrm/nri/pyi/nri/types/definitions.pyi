# (generated with --quick)

import collections
from typing import Callable, Dict, Iterable, Optional, Sized, Tuple, Type, TypeVar, Union

Failure: _Return
Success: _Return

_TMachineInfo = TypeVar('_TMachineInfo', bound=MachineInfo)
_TRAPLConfig = TypeVar('_TRAPLConfig', bound=RAPLConfig)
_TRAPLPackageConfig = TypeVar('_TRAPLPackageConfig', bound=RAPLPackageConfig)
_TTemperatureSamples = TypeVar('_TTemperatureSamples', bound=TemperatureSamples)

class EnergySamples(Dict[_PkgID, _MicroJoules]):
    def __init__(self, val: Dict[_PkgID, _MicroJoules]) -> None: ...

class FreqControl(Dict[_CoreID, _Hz]):
    def __init__(self, val: Dict[_CoreID, _Hz]) -> None: ...

class MachineInfo(tuple):
    __slots__ = ["energySamples", "tempSamples", "time", "time_last"]
    __dict__: collections.OrderedDict[str, Optional[Union[EnergySamples, TemperatureSamples, _Time]]]
    _field_defaults: collections.OrderedDict[str, Optional[Union[EnergySamples, TemperatureSamples, _Time]]]
    _field_types: collections.OrderedDict[str, type]
    _fields: Tuple[str, str, str, str]
    energySamples: Optional[EnergySamples]
    tempSamples: TemperatureSamples
    time: _Time
    time_last: _Time
    def __getnewargs__(self) -> Tuple[_Time, _Time, Optional[EnergySamples], TemperatureSamples]: ...
    def __getstate__(self) -> None: ...
    def __init__(self, *args, **kwargs) -> None: ...
    def __new__(cls: Type[_TMachineInfo], time_last: _Time, time: _Time, energySamples: Optional[EnergySamples], tempSamples: TemperatureSamples) -> _TMachineInfo: ...
    def _asdict(self) -> collections.OrderedDict[str, Optional[Union[EnergySamples, TemperatureSamples, _Time]]]: ...
    @classmethod
    def _make(cls: Type[_TMachineInfo], iterable: Iterable[Optional[Union[EnergySamples, TemperatureSamples, _Time]]], new = ..., len: Callable[[Sized], int] = ...) -> _TMachineInfo: ...
    def _replace(self: _TMachineInfo, **kwds: Optional[Union[EnergySamples, TemperatureSamples, _Time]]) -> _TMachineInfo: ...

class PcapControl(Dict[_PkgID, _MicroWatts]):
    def __init__(self, val: Dict[_PkgID, _MicroWatts]) -> None: ...

class RAPLConfig(tuple):
    __slots__ = ["packageConfig"]
    __dict__: collections.OrderedDict[str, Dict[_PkgID, RAPLPackageConfig]]
    _field_defaults: collections.OrderedDict[str, Dict[_PkgID, RAPLPackageConfig]]
    _field_types: collections.OrderedDict[str, type]
    _fields: Tuple[str]
    packageConfig: Dict[_PkgID, RAPLPackageConfig]
    def __getnewargs__(self) -> Tuple[Dict[_PkgID, RAPLPackageConfig]]: ...
    def __getstate__(self) -> None: ...
    def __init__(self, *args, **kwargs) -> None: ...
    def __new__(cls: Type[_TRAPLConfig], packageConfig: Dict[_PkgID, RAPLPackageConfig]) -> _TRAPLConfig: ...
    def _asdict(self) -> collections.OrderedDict[str, Dict[_PkgID, RAPLPackageConfig]]: ...
    @classmethod
    def _make(cls: Type[_TRAPLConfig], iterable: Iterable[Dict[_PkgID, RAPLPackageConfig]], new = ..., len: Callable[[Sized], int] = ...) -> _TRAPLConfig: ...
    def _replace(self: _TRAPLConfig, **kwds: Dict[_PkgID, RAPLPackageConfig]) -> _TRAPLConfig: ...

class RAPLPackageConfig(tuple):
    __slots__ = ["constraint_0_max_power_uw", "constraint_0_name", "constraint_0_time_window_us", "constraint_1_max_power_uw", "constraint_1_name", "constraint_1_time_window_us", "enabled"]
    __dict__: collections.OrderedDict[str, Union[int, str]]
    _field_defaults: collections.OrderedDict[str, Union[int, str]]
    _field_types: collections.OrderedDict[str, type]
    _fields: Tuple[str, str, str, str, str, str, str]
    constraint_0_max_power_uw: _MicroWatts
    constraint_0_name: str
    constraint_0_time_window_us: int
    constraint_1_max_power_uw: _MicroWatts
    constraint_1_name: str
    constraint_1_time_window_us: int
    enabled: bool
    def __getnewargs__(self) -> Tuple[bool, _MicroWatts, str, int, _MicroWatts, str, int]: ...
    def __getstate__(self) -> None: ...
    def __init__(self, *args, **kwargs) -> None: ...
    def __new__(cls: Type[_TRAPLPackageConfig], enabled: bool, constraint_0_max_power_uw: _MicroWatts, constraint_0_name: str, constraint_0_time_window_us: int, constraint_1_max_power_uw: _MicroWatts, constraint_1_name: str, constraint_1_time_window_us: int) -> _TRAPLPackageConfig: ...
    def _asdict(self) -> collections.OrderedDict[str, Union[int, str]]: ...
    @classmethod
    def _make(cls: Type[_TRAPLPackageConfig], iterable: Iterable[Optional[Union[int, str]]], new = ..., len: Callable[[Sized], int] = ...) -> _TRAPLPackageConfig: ...
    def _replace(self: _TRAPLPackageConfig, **kwds: Optional[Union[int, str]]) -> _TRAPLPackageConfig: ...

class TemperatureSamples(tuple):
    __slots__ = ["core_t_celcius", "pkg_t_celcius"]
    __dict__: collections.OrderedDict[str, Dict[Union[_CoreID, _PkgID], _Temperature]]
    _field_defaults: collections.OrderedDict[str, Dict[Union[_CoreID, _PkgID], _Temperature]]
    _field_types: collections.OrderedDict[str, type]
    _fields: Tuple[str, str]
    core_t_celcius: Dict[_CoreID, _Temperature]
    pkg_t_celcius: Dict[_PkgID, _Temperature]
    def __getnewargs__(self) -> Tuple[Dict[_CoreID, _Temperature], Dict[_PkgID, _Temperature]]: ...
    def __getstate__(self) -> None: ...
    def __init__(self, *args, **kwargs) -> None: ...
    def __new__(cls: Type[_TTemperatureSamples], core_t_celcius: Dict[_CoreID, _Temperature], pkg_t_celcius: Dict[_PkgID, _Temperature]) -> _TTemperatureSamples: ...
    def _asdict(self) -> collections.OrderedDict[str, Dict[Union[_CoreID, _PkgID], _Temperature]]: ...
    @classmethod
    def _make(cls: Type[_TTemperatureSamples], iterable: Iterable[Dict[Union[_CoreID, _PkgID], _Temperature]], new = ..., len: Callable[[Sized], int] = ...) -> _TTemperatureSamples: ...
    def _replace(self: _TTemperatureSamples, **kwds: Dict[Union[_CoreID, _PkgID], _Temperature]) -> _TTemperatureSamples: ...

class _CoreID(int):
    def __init__(self, val: int) -> None: ...

class _Hz(int):
    def __init__(self, val: int) -> None: ...

class _MicroJoules(int):
    def __init__(self, val: int) -> None: ...

class _MicroWatts(int):
    def __init__(self, val: int) -> None: ...

class _PUID(int):
    def __init__(self, val: int) -> None: ...

class _PkgID(int):
    def __init__(self, val: int) -> None: ...

class _Return(bool):
    def __init__(self, val: bool) -> None: ...

class _Temperature(float):
    def __init__(self, val: float) -> None: ...

class _Time(float):
    def __init__(self, val: float) -> None: ...